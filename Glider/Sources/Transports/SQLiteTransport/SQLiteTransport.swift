//
//  Glider
//  Fast, Lightweight yet powerful logging system for Swift.
//
//  Created by Daniele Margutti
//  Email: <hello@danielemargutti.com>
//  Web: <http://www.danielemargutti.com>
//
//  Copyright ©2022 Daniele Margutti. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

/// `SQLiteTransport` uses a combination of `ThrottledTransport` and SQLite3 database
/// to perform efficent storage and query for events.
/// It should be the default choice for all uses.
open class SQLiteTransport: Transport, ThrottledTransportDelegate {
    
    // MARK: - Public Properties
    
    /// Dispatch queue.
    public var queue: DispatchQueue?
    
    /// SQLiteTransport configuration.
    public let configuration: Configuration
    
    /// Transport is enabled.
    public var isEnabled: Bool = true

    /// Pending payloads contained into the buffer.
    public var pendingPayloads: [ThrottledTransport.Payload] {
        throttledTransport?.pendingPayloads ?? []
    }
    
    /// Delegate.
    public weak var delegate: SQLiteTransportDelegate?
    
    /// SQLite3 Database.
    public let db: SQLiteDb
    
    /// Database user's version.
    public var databaseVersion: Int = 0
    
    // MARK: - Private Properties

    /// Throttled transport.
    private var throttledTransport: ThrottledTransport?
    
    /// The date of the last purge for old logs.
    private var lastPurge = Date()
    
    // MARK: - Initialization
    
    /// Initialize a new SQLite Transport with configuration.
    ///
    /// - Parameter configuration: configuration.
    public init(configuration: Configuration) throws {
        self.configuration = configuration
        
        let fileExists = configuration.databaseLocation.fileExists

        self.db = try SQLiteDb(configuration.databaseLocation, options: configuration.databaseOptions)
        self.databaseVersion = configuration.databaseVersion
        self.delegate = configuration.delegate
        self.queue = configuration.queue
        
        if !fileExists {
            try prepareDatabaseStructure()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.sqliteTransport(self, openedDatabaseAtURL: configuration.databaseLocation, isFileExist: fileExists)
            }
        }
        
        self.throttledTransport = configuration.throttledTransport
        self.configuration.throttledTransport.delegate = self // must watch throttled transport delegate
    }
    
    /// Initialize a new SQLite transport with given location and builder function.
    ///
    /// - Parameters:
    ///   - databaseLocation: database location.
    ///   - builder: builder callback.
    public convenience init(databaseLocation: SQLiteDb.Location, _ builder: ((inout Configuration) -> Void)? = nil) throws {
        try self.init(configuration: Configuration(databaseLocation: databaseLocation, builder))
    }
    
    /// Flush remaining pendng payloads.
    public func flushPendingLogs() {
        throttledTransport?.flush()
    }
    
    /// Purge old logs.
    /// This happens automatically so generally you don't need to call it directly.
    /// If not enough time is elapsed since last purge the operation is skipped automatically with no confirmation.
    ///
    /// - Parameter vacuum: optionally vacuum the database, by default is set to `true`.
    /// - Returns: Removed Logs
    @discardableResult
    public func purge(vacuum: Bool = true) throws -> Int64 {
       try queue!.sync {
           guard let logsLifeTimeInterval = configuration.lifetimeInterval,
                 let flushMinimumInterval = configuration.purgeMinInterval,
                  Date().timeIntervalSince(lastPurge) >= flushMinimumInterval else {
                return 0
            }
           
           // Purge old logs
           let oldestAge = Date(timeInterval: -logsLifeTimeInterval, since: Date())
           try db.update(sql: "DELETE FROM log WHERE timestamp < \(oldestAge.timeIntervalSince1970)")
           let countRemoved = try db.select(sql: "SELECT changes()").int64(column: 0) ?? 0
           
           if vacuum { // vacum database
               try db.vacuum()
           }
           
           lastPurge = Date()
           
           // alert delegate
           if let delegate = delegate {
               DispatchQueue.main.async { [weak self] in
                   guard let self = self else { return }
                   delegate.sqliteTransport(self, purgedLogs: countRemoved)
               }
           }
           
           return countRemoved
        }
    }
    
    /// This method is called when a new database is created.
    /// Tables structure are created here. You can override this class and make your
    /// own tables by customizing every aspect of the storage.
    open func prepareDatabaseStructure() throws {
        try? db.setForeignKeys(enabled: true) // enable foreign keys enforcement if available
        
        try db.update(sql: Queries.mainTable)
        try db.update(sql: Queries.tagsTable)
        try db.update(sql: Queries.extraTable)
    }
    
    /// This method receive the payloads (event + formatted messages if one or more formatters are set).
    /// You can override this method to perform your own store.
    ///
    /// - Parameter payloads: payloads.
    open func storeEventsPayloads(_ payloads: [ThrottledTransport.Payload]) throws  {
        // Payloads are recorder by chunks in order to avoid too many writes.
        let payloadStmt = try db.prepare(sql: Queries.recordEvent)
        let tagStmt = try db.prepare(sql: Queries.recordTag)
        let extraStmt = try db.prepare(sql: Queries.recordExtra)
        
        // The entire process is inside a transaction.
        try db.updateWithTransaction {
            try payloads.forEach({
                try executeInsertPayloadStmt($0,
                                             payloadStmt: payloadStmt, tagStmt: tagStmt, extraStmt: extraStmt)
            })
        }
        
        if let delegate = delegate {
            DispatchQueue.main.async { [weak self] in
                delegate.sqliteTransport(self!, writtenPayloads: payloads)
            }
        }
        
        // ask for purge old logs if possible
        try purge(vacuum: true)
    }
    
    /// This method is called when the database version should be updated.
    /// You can perform your own migration operations here.
    ///
    /// - Parameters:
    ///   - oldVersion: old version.
    ///   - currentVersion: new version.
    open func migrateDatabaseSchema(from oldVersion: Int, to currentVersion: Int) throws {
        
    }
    
    // MARK: - ThrottledTransportDelegate
    
    public func record(_ transport: ThrottledTransport,
                       events: [ThrottledTransport.Payload],
                       reason: ThrottledTransport.FlushReason,
                       _ completion: ThrottledTransport.Completion?) {
        do {
            try storeEventsPayloads(events)
        } catch {
            if let delegate = delegate {
                DispatchQueue.main.async { [weak self] in
                    delegate.sqliteTransport(self!, didFailQueryWithError: error)
                }
            }
        }
    }
    
    // MARK: - Conformance
    
    public func record(event: Event) -> Bool {
        guard isEnabled else { return false }
        
        return throttledTransport?.record(event: event) ?? false
    }
    
    // MARK: - Private Functions
    
    /// Store a single payload into database.
    ///
    /// - Parameter payload: payload.
    /// - Returns: Bool
    private func executeInsertPayloadStmt(_ payload: ThrottledTransport.Payload,
                                          payloadStmt: SQLiteDb.Statement?,
                                          tagStmt: SQLiteDb.Statement?,
                                          extraStmt: SQLiteDb.Statement?) throws {
        let event = payload.0
        
        // Add log
        try payloadStmt?.bind(param: 1, event.id)
        try payloadStmt?.bind(param: 2, event.timestamp)
        try payloadStmt?.bind(param: 3, event.level.rawValue)
        try payloadStmt?.bind(param: 4, event.category?.description)
        try payloadStmt?.bind(param: 5, event.subsystem?.description)
        try payloadStmt?.bind(param: 6, payload.1?.asString() ?? event.message)
        try payloadStmt?.bind(param: 7, event.scope.function)
        try payloadStmt?.bind(param: 8, event.scope.fileName)
        try payloadStmt?.bind(param: 9, event.scope.fileLine)
        if let isCodable = event.serializedObjectMetadata?["codable"] as? Bool, isCodable == true {
            try payloadStmt?.bind(param: 10, event.serializedObjectData?.asString())
            try payloadStmt?.bindNull(param: 11)
        } else {
            try payloadStmt?.bindNull(param: 10)
            try payloadStmt?.bind(param: 11, event.serializedObjectData)
        }
        try payloadStmt?.bind(param: 11, event.serializedObjectMetadata?.asString())
        
        try payloadStmt?.step()
        try payloadStmt?.reset()

        // Add tags
        if (event.allTags?.isEmpty ?? true) == false {
            try event.allTags?.forEach({ key, value in
                try tagStmt?.bind(param: 1, event.id)
                try tagStmt?.bind(param: 2, key)
                try tagStmt?.bind(param: 3, value)
            })
            try tagStmt?.step()
            try tagStmt?.reset()
        }
        
        // Add extra
        if (event.allExtra?.values.isEmpty ?? true) == false {
            try event.allExtra?.values.forEach({ key, value in
                try extraStmt?.bind(param: 1, event.id)
                try extraStmt?.bind(param: 2, key)
                try extraStmt?.bind(param: 3, value?.asData())
            })
            try extraStmt?.step()
            try extraStmt?.reset()
        }
    }
    
    /// Perform migration if needed.
    ///
    /// - Throws: throw an exception if something fails.
    @discardableResult
    private func migrateDatabaseIfNeeded() throws -> Bool {
        let currentVersion = try db.getVersion(.user)
        guard currentVersion < self.databaseVersion else {
            return false
        }
        
        try migrateDatabaseSchema(from: currentVersion, to: databaseVersion)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.sqliteTransport(self, schemaMigratedFromVersion: currentVersion, toVersion: self.databaseVersion)
        }
        
        try db.setVersion(self.databaseVersion)
        return true
    }
    
}

// MARK: - Queries

fileprivate extension SQLiteTransport {
    
    enum Queries {
        
        // MARK: - Table Creation Queries
        
        /// Statement used to create log table.
        static let mainTable = """
            CREATE TABLE IF NOT EXISTS log (
                eventId TEXT PRIMARY KEY,
                timestamp INTEGER DEFAULT (strftime('%s','now')),
                level INTEGER,
                category TEXT,
                subsystem TEXT,
                message TEXT,
                functionName TEXT,
                file TEXT,
                fileLine INT,
                objectJSON TEXT,
                objectData BLOB,
                objectMetadata TEXT
            );
        """
        
        /// Statement used to create log table.
        static let tagsTable = """
            CREATE TABLE IF NOT EXISTS tags (
                eventId INTEGER,
                key TEXT NOT NULL,
                value TEXT,
                FOREIGN KEY (eventId)
                    REFERENCES log (eventId)
            );
        """
        
        /// Statement used to create extra table.
        static let extraTable = """
            CREATE TABLE IF NOT EXISTS extra (
                eventId INTEGER,
                key TEXT NOT NULL,
                value BLOB,
                FOREIGN KEY (eventId)
                    REFERENCES log (eventId)
            );
        """
        
        // MARK: - Insert Queries
        
        /// Statement compiled to insert payload into db.
        static let recordEvent = """
            INSERT INTO log
                (eventId, timestamp, level, category, subsystem, message, functionName, file, fileLine, objectJSON, objectData, objectMetadata)
            VALUES
                (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        /// Statement compiled to insert tags into db.
        static let recordTag = """
            INSERT INTO tags
                (eventId, key, value)
            VALUES
                (?, ?, ?);
        """
        
        /// Statement compiled to insert extra into db.
        static let recordExtra = """
            INSERT INTO extra
                (eventId, key, value)
            VALUES
                (?, ?, ?);
        """
    }
    
}

// MARK: - Configuration

extension SQLiteTransport {
    
    public struct Configuration {
        
        /// Dispatch queue.
        public var queue = DispatchQueue(label: "Glider.\(UUID().uuidString)")

        /// The maximum age of a log before it it will be removed automatically
        /// to preserve the space. Set as you needs.
        ///
        /// By default is 1h.
        public var lifetimeInterval: TimeInterval?
        
        /// Flushing old logs can't happens every time we wrote something
        /// on db. So this interval is the minimum time interval to pass
        /// before calling flush another time.
        /// Typically is set as 3x the `logsLifeTimeInterval`.
        public var purgeMinInterval: TimeInterval?
        
        /// Delegate.
        public weak var delegate: SQLiteTransportDelegate?
        
        /// Location of the database.
        public var databaseLocation: SQLiteDb.Location
        
        /// Options for database creation.
        /// By default is the standard initialization of `SQLiteDb.Options`.
        public var databaseOptions: SQLiteDb.Options = .init()
        
        /// Database user's version.
        /// By default is 0.
        public var databaseVersion: Int = 0
        
        /// Throttled transport used to perform buffering on database.
        ///
        /// By default is initialized with the default configuration
        /// of the `ThrottledTransport`.
        public var throttledTransport: ThrottledTransport
        
        // MARK: - Initialization
        
        /// Initialize Configuration.
        ///
        /// - Parameters:
        ///   - databaseLocation: databasse location.
        ///   - builder: builder function to setup additional settings.
        public init(databaseLocation: SQLiteDb.Location,
                    _ builder: ((inout Configuration) -> Void)?) {
            self.databaseLocation = databaseLocation
            self.throttledTransport = ThrottledTransport.init({ _ in })
            self.purgeMinInterval = (lifetimeInterval != nil ? lifetimeInterval! * 3.0 : nil)
            builder?(&self)
        }
        
    }
    
}
