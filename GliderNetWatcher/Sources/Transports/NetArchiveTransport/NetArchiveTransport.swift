//
//  Glider
//  Fast, Lightweight yet powerful logging system for Swift.
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Authors:
//   - Daniele Margutti <hello@danielemargutti.com>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation
import Glider

/// The `NetArchiveTransport` class is used to store network activity in a compact
/// searchable archive powered by SQLite3.
public class NetArchiveTransport: Transport, ThrottledTransportDelegate {
    
    // MARK: - Public Properties
    
    /// The `DispatchQueue` to use for the recorder.
    public var queue: DispatchQueue
    
    /// Configuration used for this transport.
    public let configuration: Configuration
    
    /// Is logging service enabled.
    public var isEnabled: Bool = true
    
    /// Ignored for this kind of transport.
    public var minimumAcceptedLevel: Level? = nil
    
    /// Underlying storage database.
    public let db: SQLiteDb
    
    // MARK: - Private Properties
    
    /// Throttled transport.
    private var throttledTransport: ThrottledTransport?
    
    /// The date of the last purge for old logs.
    private var lastPurge = Date()
    
    // MARK: - Initialization
    
    /// Initialize a new database transport for network events with a given configuration.
    ///
    /// - Parameter configuration: configuration.
    public init(configuration: Configuration) throws {
        self.configuration = configuration
        self.isEnabled = configuration.isEnabled
        self.queue = configuration.queue
        
        let fileExists = configuration.databaseLocation.fileExists
        self.db = try SQLiteDb(configuration.databaseLocation, options: configuration.databaseOptions)
        
        if !fileExists {
            try prepareDatabaseStructure()
        }
        
        self.throttledTransport = ThrottledTransport(configuration: configuration.throttledTransport)
        self.throttledTransport?.delegate = self // must watch throttled transport delegate
    }
    
    // MARK: - Protocol Conformance
    
    public func record(event: Event) -> Bool {
        throttledTransport?.record(event: event) ?? false
    }
    
    public func record(_ transport: ThrottledTransport,
                       events: [ThrottledTransport.Payload],
                       reason: ThrottledTransport.FlushReason,
                       _ completion: ThrottledTransport.Completion?) {
        do {
            try storePayloads(events.compactMap({ $0.0.object as? NetworkEvent}))
        } catch {
            print(error)
        }
    }
    
    /// Purge old logs.
    /// This happens automatically so generally you don't need to call it directly.
    /// If not enough time is elapsed since last purge the operation is skipped automatically with no confirmation.
    ///
    /// - Parameter vacuum: optionally vacuum the database, by default is set to `true`.
    /// - Returns: Removed Logs
    @discardableResult
    public func purge(vacuum: Bool = true) throws -> Int64 {
        try queue.sync {
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
            return countRemoved
        }
    }
    
    // MARK: - Private Functions
    
    private func storePayloads(_ events: [NetworkEvent]) throws {
        let stmt = try db.prepare(sql: Queries.recordEvent)
        
        // The entire process is inside a transaction.
        try db.updateWithTransaction {
            try events.forEach({
                try executeStmt(stmt, forEvent: $0)
            })
        }
        
        // ask for purge old logs if possible
        try purge(vacuum: true)
    }
    
    private func executeStmt(_ stmt: SQLiteDb.Statement?, forEvent event: NetworkEvent) throws {
        try stmt?.bind(param: 1, event.id)
        try stmt?.bind(param: 2, event.startDate.timeIntervalSince1970)
        try stmt?.bind(param: 3, event.duration)
        try stmt?.bind(param: 4, event.url.absoluteString)
        try stmt?.bind(param: 5, event.host)
        try stmt?.bind(param: 6, event.port)
        try stmt?.bind(param: 7, event.scheme)
        try stmt?.bind(param: 8, event.method)
        try stmt?.bind(param: 9, event.headers)
        try stmt?.bind(param: 10, event.credentials)
        try stmt?.bind(param: 11, event.cookies)
        try stmt?.bind(param: 12, event.statusCode)
        try stmt?.bind(param: 13, event.responseData)
        try stmt?.bind(param: 14, event.responseErrorDescription)
        try stmt?.bind(param: 15, event.urlRequest?.cURLCommand())

        try stmt?.step()
        try stmt?.reset()
    }
    
    /// This method is called when a new database is created.
    /// Tables structure are created here. You can override this class and make your
    /// own tables by customizing every aspect of the storage.
    private func prepareDatabaseStructure() throws {
        try? db.setForeignKeys(enabled: true) // enable foreign keys enforcement if available
        
        try db.update(sql: Queries.mainTable)
    }
    
}


// MARK: - Queries

fileprivate extension NetArchiveTransport {
    
    enum Queries {
        
        // MARK: - Table Creation Queries
        
        /// Statement used to create log table.
        static let mainTable = """
            CREATE TABLE IF NOT EXISTS call (
                id TEXT PRIMARY KEY,
                timestamp INTEGER,
                duration REAL,
                url TEXT,
                host TEXT,
                port INT,
                scheme TEXT,
                method TEXT,
                headers TEXT,
                credentials INT,
                cookies TEXT,
                code TEXT,
                data BLOB,
                error TEXT,
                cURL TEXT
            );
        """
        
        // MARK: - Insert Queries
        
        /// Statement compiled to insert payload into db.
        static let recordEvent = """
            INSERT INTO call
                (id, timestamp, duration, url, host, port, scheme, method, headers, credentials, cookies, code, data, error, cURL)
            VALUES
                (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
    }
}
