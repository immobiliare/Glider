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
    public var queue: DispatchQueue? {
        set { throttledTransport?.queue = newValue }
        get { throttledTransport?.queue }
    }

    /// Size of the buffer.
    public var bufferSize: Int {
        throttledTransport!.bufferSize
    }
    
    /// Flush interval.
    public var flushInterval: TimeInterval? {
        throttledTransport?.flushInterval
    }
    
    /// Delegate.
    public weak var delegate: SQLiteTransportDelegate?
    
    /// SQLite3 Database.
    public let db: SQLiteDb
    
    /// Database user's version.
    public var databaseVersion: Int = 0

    /// Formatters for data.
    public var formatters: [EventFormatter] {
        set { throttledTransport!.formatters = newValue }
        get { throttledTransport!.formatters }
    }
    
    // MARK: - Private Properties
        
    /// Precompiled statements for insertions.
    private var payloadStmt: SQLiteDb.Statement?
    private var tagStmt: SQLiteDb.Statement?
    private var extraStmt: SQLiteDb.Statement?

    /// Throttled transport.
    private var throttledTransport: ThrottledTransport?
    
    // MARK: - Initialization
    
    /// Initialize a new SQLite3 local database transport with a db at given URL.
    /// If database does not exists it will be created automatically.
    ///
    /// - Parameters:
    ///   - location: location of the database. Typically `fileURL` is used to save a local file on disk.
    ///   - options: options for SQLite3 database.
    ///   - version: version of the SQLite database. If an existing log dictionary is opened with old version `migrateDatabase()` is called.
    ///   - formatters: formatters used to eventually convert messages.
    ///   - bufferSize: size of the buffer. Messages are collected in groups before being written into db. By default is 50 events.
    ///   - flushInterval: auto flush interval used to write data on db even if not enough events are collected. By default is `15`.
    ///   - queue: queue in which the operations are executed into.
    ///   - delegate: delegate.
    public init(location: SQLiteDb.Location,
                options: SQLiteDb.Options = .init(),
                version: Int = 0,
                formatters: [EventFormatter] = [],
                bufferSize: Int = 50,
                flushInterval: TimeInterval? = 15,
                queue: DispatchQueue? = nil,
                delegate: SQLiteTransportDelegate? = nil) throws {
        
        let fileExists = location.fileExists

        self.db = try SQLiteDb(location, options: options)
        self.databaseVersion = version
        self.delegate = delegate
        
        if !fileExists {
            try prepareDatabaseStructure()
        }
        
        self.throttledTransport = ThrottledTransport(bufferSize: bufferSize,
                                                     flushInterval: flushInterval,
                                                     formatters: formatters,
                                                     queue: queue,
                                                     delegate: self)
    
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
    open func storeEventsPayloads(_ payloads: [ThrottledTransport.Payload]) {
        // Payloads are recorder by chunks in order to avoid too many writes.
        do {
            if payloadStmt == nil { // Prepare and reuse statement
                payloadStmt = try db.prepare(sql: Queries.recordEvent)
                tagStmt = try db.prepare(sql: Queries.recordTag)
                extraStmt = try db.prepare(sql: Queries.recordExtra)
            }

            // The entire process is inside a transaction.
            try db.updateWithTransaction {
                try payloads.forEach({
                    try executeInsertPayloadStmt($0)
                })
            }
            
        } catch {
            print("Error: \(error)")
        }
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
        storeEventsPayloads(events)
    }
    
    // MARK: - Conformance
    
    public func record(event: Event) -> Bool {
        throttledTransport?.record(event: event) ?? false
    }
    
    // MARK: - Private Functions
    
    /// Store a single payload into database.
    ///
    /// - Parameter payload: payload.
    /// - Returns: Bool
    private func executeInsertPayloadStmt(_ payload: ThrottledTransport.Payload) throws {
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
        if let isCodable = event.serializedObject?.metadata?["codable"] as? Bool, isCodable == true {
            try payloadStmt?.bind(param: 10, event.serializedObject?.data.asString())
            try payloadStmt?.bindNull(param: 11)
        } else {
            try payloadStmt?.bindNull(param: 10)
            try payloadStmt?.bind(param: 11, event.serializedObject?.data)
        }
        try payloadStmt?.bind(param: 11, event.serializedObject?.metadata?.asString())
        
        try payloadStmt?.step()
        
        // Add tags
        try event.allTags?.forEach({ key, value in
            try tagStmt?.bind(param: 1, event.id)
            try tagStmt?.bind(param: 2, key)
            try tagStmt?.bind(param: 3, value)
        })
        try tagStmt?.step()
        
        // Add extra
        try event.allExtra?.forEach({ key, value in
            try extraStmt?.bind(param: 1, event.id)
            try extraStmt?.bind(param: 2, key)
            try extraStmt?.bind(param: 3, value?.asData())
        })
        try extraStmt?.step()
        
        // Reset the state
        try payloadStmt?.reset()
        try tagStmt?.reset()
        try extraStmt?.reset()
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
        
        try migrateDatabaseSchema(from: currentVersion, to: self.databaseVersion)
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
