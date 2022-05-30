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
    public init(location: SQLiteDb.Location,
                options: SQLiteDb.Options = .init(),
                version: Int = 0,
                formatters: [EventFormatter] = [],
                bufferSize: Int = 50,
                flushInterval: TimeInterval? = 15,
                queue: DispatchQueue? = nil) throws {
        
        let fileExists = location.fileExists

        self.db = try SQLiteDb(location, options: options)
        self.databaseVersion = version
        
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
        
    }
    
    /// This method receive the payloads (event + formatted messages if one or more formatters are set).
    /// You can override this method to perform your own store.
    ///
    /// - Parameter payloads: payloads.
    open func storeEventsPayloads(_ payloads: [ThrottledTransport.Payload]) {
        
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
        
        /// Statement used to create log table.
        static let createLogTable = """
            CREATE TABLE IF NOT EXISTS log (
                timestamp INTEGER DEFAULT (strftime('%s','now')),
                level INTEGER,
                category TEXT,
                subsystem TEXT,
                message TEXT,
                functionName TEXT,
                file TEXT,
                fileLine INT,
                userAttrs TEXT,
                ctxAttrs TEXT,
                scopeName TEXT,
                scopeLevel INTEGER,
                object TEXT
            );
        """
    "
    }
    
}
