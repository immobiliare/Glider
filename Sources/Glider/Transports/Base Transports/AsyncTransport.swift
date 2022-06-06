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

/// `AsyncTransport` is a transport specifically made for asynchrouns request.
/// It store logs locally before sending to the network and can retry unsent payloads.
/// The underlying storage is an SQLite in memory database by default.
public class AsyncTransport: Transport {
    public typealias Chunk = (event: Event, message: SerializableData?, countAttempts: Int)
    
    // MARK: - Public Properties
    
    /// GCD queue for operations.
    public var queue: DispatchQueue?
    
    /// Configuration used.
    public let configuration: Configuration
    
    /// Delegate which receive events from transport.
    public weak var delegate: AsyncTransportDelegate?
        
    // MARK: - Private Properties
    
    /// Cache for buffered messages.
    private var db: SQLiteDb
    
    /// Statement for sqlite database record operastion.
    private var recordPayloadStmt: SQLiteDb.Statement?
    
    /// Autoflush timer.
    private var timer: Timer?

    
    // MARK: - Initialization
    
    /// Initialize a new AsyncTransport system.
    ///
    /// - Parameters:
    ///   - bufferSize: size of the buffer to hold data.
    ///   - blockSize: size of each block sent outside for external sending.
    ///   - flushInterval: periodic flush interval, `nil` to not set.
    ///   - formatters: formatters used to format data.
    ///   - location: storage where the buffered data is set. By default is `inMemory`.
    ///   - options: storage options.
    ///   - queue: queue in which the operations are executed into.
    ///   - delegate: delegate for events.
    public init(_ builder: ((inout Configuration) -> Void)? = nil) throws {
        var config = Configuration()
        builder(&config)
        
        self.configuration = config
        
        let fileExists = config.bufferStorage.fileExists
        self.db = try SQLiteDb(config.bufferStorage, options: config.bufferStorageOptions)
        if !fileExists {
            try prepareDatabase()
        }
        
        self.queue = config.queue
        self.delegate = config.delegate
        
        setupAutoFlushInterval()
    }
    
    // MARK: - Conformance
    
    public func record(event: Event) -> Bool {
        queue!.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let message = self.configuration.formatters.format(event: event)
                _ = try self.store(event: event, withMessage: message, retryAttempt: 0)
                
                if self.configuration.flushOnRecord,
                   let countStoredItems = try? self.db.select(sql: "SELECT COUNT(*) FROM buffer").integer(column: 0) ?? 0,
                   countStoredItems > self.configuration.bufferSize {
                    self.flush()
                }
            } catch {
                self.delegate?.asyncTransport(self, errorOccurred: error)
            }
        }
        
        return true
    }
        
    /// Perform manual flush on buffer data.
    public func flush() {
        queue!.async {
            self.flushCache()
        }
    }
    
    /// Count the number of buffered events pending for sent.
    ///
    /// - Returns: Int
    public func countBufferedEvents() throws -> Int {
        queue!.sync {
            do {
                return try db.select(sql: "SELECT COUNT(*) FROM buffer").integer(column: 0) ?? 0
            } catch {
                return 0
            }
        }
    }
    
    // MARK: - Overridable Functions
    
    /// Override this method to send a chunk of payloads to a remote service.
    ///
    /// - Parameters:
    ///   - chunk: chunk of payloads to send.
    ///   - completion: call completion to allows retry or send `nil` to mark them as sent and prevent them to be sent again.
    open func record(chunk: [Chunk], completion: ((Error?) -> Void)) {
        completion(nil) // by default are marked as sent
        // Your own implementation should be manage this.
    }
    
    // MARK: - Private Functions
    
    /// Prepare the database infrastructure.
    private func prepareDatabase() throws {
        try db.setForeignKeys(enabled: true)
        try db.update(sql: Queries.createBufferLogTable)
        
        self.recordPayloadStmt = try db.prepare(sql: Queries.recordPayload)
    }
    
    /// Store message in cache.
    ///
    /// - Parameters:
    ///   - event: event to store.
    ///   - message: associated formatted message.
    ///   - retryAttempt: retry attempt.
    @discardableResult
    private func store(event: Event, withMessage message: SerializableData?, retryAttempt: Int) throws -> String {
        let data = try JSONEncoder().encode(event)
        try recordPayloadStmt?.bind([
            event.timestamp.timeIntervalSince1970,
            data,
            message,
            retryAttempt
        ])
        
        try recordPayloadStmt?.step()
        return event.id
    }
    
    private func setupAutoFlushInterval() {
        guard let flushInterval = configuration.flushInterval else { return }
        
        self.timer?.invalidate()
        let timer = Timer(timeInterval: flushInterval,
                          target: self,
                          selector: #selector(tick),
                          userInfo: nil,
                          repeats: true)
        
        DispatchQueue.main.async {
            RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
        }
        
        self.timer = timer
    }
    
    @objc
    private func tick() {
        queue!.async {
            self.flushCache()
        }
    }
        
    /// Retrive the next chunk of data and attempt to sent.
    /// - Returns: Coun events marked to sent.
    @discardableResult
    private func flushCache() -> Int {
        do {
            // Cleanup cache if needed.
            _ = try vacuumCache()
            let chunk = try fetchNextPayloadsChunk()
            
            guard chunk.isEmpty == false else {
                return 0 // no pending payloads
            }
            
            record(chunk: chunk) { [weak self] error in
                guard let self = self else { return }
                
                guard let error = error else {
                    if let delegate = delegate {
                        let sentIDs = chunk.map({ $0.event.id })
                        delegate.asyncTransport(self, sentEventIDs: Set(sentIDs))
                    }
                    return // all sent, nothing to do
                }
                
                // increment attempt, re-insert data into database
                var retryIDs = [(String, Int)]()
                var discardedIDs = Set<String>()
                for payload in chunk {
                    if (payload.countAttempts + 1) <= configuration.maxRetries {
                        if let id = try? self.store(event: payload.event, withMessage: payload.message,
                                                    retryAttempt: payload.countAttempts + 1) {
                            retryIDs.append( (id, payload.countAttempts + 1) )
                        }
                    } else {
                        discardedIDs.insert(payload.event.id)
                    }
                }
                
                if retryIDs.isEmpty == false || discardedIDs.isEmpty == false  {
                    DispatchQueue.main.async {
                        self.delegate?.asyncTransport(self,
                                                      willPerformRetriesOnEventIDs: retryIDs,
                                                      discardedEvents: discardedIDs,
                                                      error: error)
                    }
                }
            }
            
            return chunk.count
        
        } catch {
            DispatchQueue.main.async {
                self.delegate?.asyncTransport(self, errorOccurred: error)
            }
            return 0
        }
    }
    
    /// Remove payloads to respect the `bufferSize` if needed.
    private func vacuumCache() throws -> Int {
        let itemsCount = try Int(db.select(sql: "SELECT COUNT(*) FROM buffer").integer(column: 0) ?? 0)
        guard itemsCount > configuration.bufferSize else {
            return itemsCount // below the maximum size
        }
        
        let limit = (itemsCount - configuration.bufferSize)
        try db.update(sql: "DELETE FROM buffer ORDER BY timestamp ASC LIMIT \(limit)")
        
        if let delegate = delegate {
            let countRemoved = try? db.select(sql: "SELECT changes()").int64(column: 0)
            DispatchQueue.main.async {
                delegate.asyncTransport(self, discardedEventsFromBuffer: countRemoved ?? 0)
            }
        }
        
        return limit
    }
    
    /// Fetch the next chunk of payloads to send to the external service.
    ///
    /// - Returns: `[CachedPayload]`
    private func fetchNextPayloadsChunk() throws -> [Chunk] {
        let result = try db.select(sql: "SELECT rowId, timestamp, data, message, retryAttempt FROM buffer ORDER BY timestamp ASC LIMIT \(configuration.chunksSize);")
        
        var rowIds = [String]()
        let payloads: [Chunk] = result.iterateRows { _, stmt in
            do {
                if let result = try fromBufferDatabase(stmt) {
                    rowIds.append(String(result.rowId))
                    return (result.event, result.message, result.attempt)
                } else {
                    return nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.delegate?.asyncTransport(self, errorOccurred: error)
                }
                return nil
            }
        }
        
        // Remove from buffer.
        try db.update(sql: "DELETE FROM buffer WHERE rowId IN (\(rowIds.joined(separator: ",")))")
        return payloads
    }
    
    /// Decode the payload from SQLite database and return the info.
    ///
    /// - Parameter stmt: statement of query from select.
    /// - Returns: (rowId, event, message, attempt)
    private func fromBufferDatabase(_ stmt: SQLiteDb.Statement) throws
        -> (rowId: Int64, event: Event, message: SerializableData?,  attempt: Int)? {
        guard let rowId = stmt.int64(column: 0),
              let eventData = stmt.data(column: 2),
              let message = stmt.data(column: 3),
              let attempt = stmt.integer(column: 4)
        else {
            return nil
        }

        let event = try JSONDecoder().decode(Event.self, from: eventData)
        return (rowId, event, message, attempt)
    }
    
}

// MARK: - AsyncTransport.Queries

internal extension AsyncTransport {
    
    enum Queries {
        
        static let createBufferLogTable = """
            CREATE TABLE IF NOT EXISTS buffer (
                timestamp INTEGER DEFAULT (strftime('%s','now')),
                data BLOB,
                message BLOB,
                retryAttempt INTEGER
            );
        """
        
        /// Statement compiled to insert payload into db.
        static let recordPayload = """
            INSERT INTO buffer
                (timestamp, data, message, retryAttempt)
            VALUES
                (?, ?, ?, ?);
        """
        
    }
    
}

// MARK: - AsyncTransport.Configuration

extension AsyncTransport {
    
    public struct Configuration {
        
        /// Data formatters.
        public var formatters = [EventFormatter]()
        
        /// Number of retries per each payloads to be sent.
        /// After reaching the maximum number payload is discarded automatically.
        ///
        /// By default this value is set to 1.
        public var maxRetries = 1
        
        /// Maximum number of messages you can store in buffer.
        /// When value is over the limit older events are automatically discarded.
        ///
        /// By default is set to 500.
        public var bufferSize: Int = 500
        
        /// Size of the chunks (number of payloads) sent at each dispatch event.
        ///
        /// By default is set to 10.
        public var chunksSize: Int = 10
        
        /// Automatic interval for flushing data in buffer.
        public var flushInterval: TimeInterval?
        
        /// Perform flush if necessary when a new record event is set.
        ///
        /// By default is set to `false`.
        public var flushOnRecord = false
        
        /// Storage where the buffered data is set.
        ///
        /// By default is `inMemory`.
        public var bufferStorage: SQLiteDb.Location = .inMemory
        
        /// Options for buffer stroage.
        public var bufferStorageOptions: SQLiteDb.Options = .init()
        
        /// GCD queue for operations.
        public var queue = DispatchQueue(label: "Glider.\(UUID().uuidString)")

        /// Delegate object.
        public weak var delegate: AsyncTransportDelegate?
        
    }
    
}

// MARK: - AsyncTransportDelegate

/// The AsyncTransportDelegate is called to inform about events from the transport itself.
public protocol AsyncTransportDelegate: AnyObject {
    
    /// Called when an error has occurred. This is a local error.
    ///
    /// - Parameters:
    ///   - transport: transport.
    ///   - error: error
    func asyncTransport(_ transport: AsyncTransport, errorOccurred error: Error)
    
    /// Called when one or more message of a chunk are not sent.
    ///
    /// - Parameters:
    ///   - transport: transport.
    ///   - retryIDs: events marked for retry attempt (tuple with id of the event, attempt)
    ///   - discardedEvents: discarded events, will be removed from cache and never sent.
    ///   - error: error occurred, typically a network related one.
    func asyncTransport(_ transport: AsyncTransport,
                        willPerformRetriesOnEventIDs retryIDs: [(String, Int)],
                        discardedEvents: Set<String>,
                        error: Error)
    
    /// Called when a chunk of data is marked as sent.
    ///
    /// - Parameters:
    ///   - transport: transport.
    ///   - sentEventIDs: event identifiers sent.
    func asyncTransport(_ transport: AsyncTransport, sentEventIDs: Set<String>)
    
    /// Called when a trim due to buffer size limit reached occour.
    ///
    /// - Parameters:
    ///   - transport: transport.
    ///   - discardedEventsFromBuffer: number of events discarded from the oldest.
    func asyncTransport(_ transport: AsyncTransport, discardedEventsFromBuffer: Int64)

}
