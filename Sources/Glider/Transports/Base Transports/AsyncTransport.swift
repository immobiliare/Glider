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
    
    // MARK: - Typealiases
    
    // payloads includes event, message and # attemopts for send
    public typealias Payload = (event: Event, message: SerializableData?, countAttempts: Int)
    public typealias Chunk = [Payload] // a chunk is a collection of payloads
    
    // MARK: - Public Properties
    
    /// GCD queue for operations.
    public var queue: DispatchQueue?
    
    /// Configuration used.
    public let configuration: Configuration
    
    /// Behaviour.
    public private(set) weak var delegate: AsyncTransportDelegate?
    
    // MARK: - Private Properties
    
    /// Cache for buffered messages.
    private var db: SQLiteDb
    
    /// Statement for sqlite database record operastion.
    private var recordPayloadStmt: SQLiteDb.Statement?
    
    /// Autoflush timer.
    private var timer: Timer?

    // MARK: - Initialization
    
    /// Initialize a new AsyncTransport.
    ///
    /// - Parameters:
    ///   - delegate: delegate object. Must implement it in order to provide custom behaviour over the logic of the transport.
    ///   - configuration: configuration.
    public init(delegate: AsyncTransportDelegate, configuration: Configuration) throws {
        self.delegate = delegate
        self.configuration = configuration
        self.queue = configuration.queue

        let fileExists = configuration.bufferStorage.fileExists
        self.db = try SQLiteDb(configuration.bufferStorage,
                               options: configuration.bufferStorageOptions)
        if !fileExists {
            try prepareDatabase()
        }
        
        setupAutoFlushInterval()
    }
    
    /// Initialize a new AsyncTransport system.
    ///
    /// - Parameters:
    ///   - delegate: delegate of events and behaviour.
    ///   - builder: builder callback to configure extra options.
    public convenience init(delegate: AsyncTransportDelegate, _ builder: ((inout Configuration) -> Void)? = nil) throws {
        let configuration = Configuration(builder)
        try self.init(delegate: delegate, configuration: configuration)
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
                   countStoredItems > self.configuration.maxEntries {
                    self.flush()
                }
            } catch {
                self.delegate?.asyncTransport(self, didFailWithError: error)
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
        do {
            return try db.select(sql: "SELECT COUNT(*) FROM buffer").integer(column: 0) ?? 0
        } catch {
            return 0
        }
    }
    
    // MARK: - Private Functions
    
    /// Prepare the database infrastructure.
    private func prepareDatabase() throws {
        try db.setForeignKeys(enabled: true)
        try db.update(sql: AsyncTransportQueries.createBufferLogTable)
        
        self.recordPayloadStmt = try db.prepare(sql: AsyncTransportQueries.recordPayload)
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
            
            delegate?.asyncTransport(self, canSendPayloadsChunk: chunk, completion: { [weak self] error in
                guard let self = self else { return }
                
                guard let error = error else {
                    self.delegate?.asyncTransport(self, sentEventIDs: Set(chunk.map({ $0.event.id })))
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
                    self.delegate?.asyncTransport(self,
                                                  didFailSendingChunkWithError: error,
                                                  willRetry: retryIDs,
                                                  willDiscard: discardedIDs)
                }
            })
            
            return chunk.count
        } catch {
            self.delegate?.asyncTransport(self, didFailWithError: error)
            return 0
        }
    }
    
    /// Remove payloads to respect the `maxEntries` if needed.
    private func vacuumCache() throws -> Int {
        let itemsCount = try Int(db.select(sql: "SELECT COUNT(*) FROM buffer").integer(column: 0) ?? 0)
        guard itemsCount > configuration.maxEntries else {
            return itemsCount // below the maximum size
        }
        
        let limit = (itemsCount - configuration.maxEntries)
        try db.update(sql: "DELETE FROM buffer ORDER BY timestamp ASC LIMIT \(limit)")
        
        let countRemoved = try? db.select(sql: "SELECT changes()").int64(column: 0)
        delegate?.asyncTransport(self, discardedEventsFromBuffer: countRemoved ?? 0)
        
        return limit
    }
    
    /// Fetch the next chunk of payloads to send to the external service.
    ///
    /// - Returns: `[CachedPayload]`
    private func fetchNextPayloadsChunk() throws -> [Payload] {
        let result = try db.select(sql: "SELECT rowId, timestamp, data, message, retryAttempt FROM buffer ORDER BY timestamp ASC LIMIT \(configuration.chunksSize);")
        
        var rowIds = [String]()
        let payloads: [Payload] = result.iterateRows { _, stmt in
            do {
                if let result = try fromBufferDatabase(stmt) {
                    rowIds.append(String(result.rowId))
                    return (result.event, result.message, result.attempt)
                } else {
                    return nil
                }
            } catch {
                delegate?.asyncTransport(self, didFailWithError: error)
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
              let attempt = stmt.integer(column: 4)
        else {
            return nil
        }

        let message = stmt.data(column: 3)
        let event = try JSONDecoder().decode(Event.self, from: eventData)
        return (rowId, event, message, attempt)
    }
    
}

// MARK: - AsyncTransport.Queries

fileprivate enum AsyncTransportQueries {
    
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
        public var maxEntries: Int = 500
        
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
        
        public init(_ builder: ((inout Configuration) -> Void)? = nil) {
            builder?(&self)
        }
        
    }
    
}

// MARK: - AsyncTransportDelegate

public protocol AsyncTransportDelegate: AnyObject {
    
    /// This method is mandatory to use the `AsyncTransport`. You should implement
    /// the behaviour to execute when a new chunk of payloads is ready to be sent
    /// to whatsover (network, db etc.).
    /// At the end of the operation you should call the `completion` callback saying to the
    /// class the result of the operation.
    /// If an error is reporteach single payload can be resent according to their attempts already made.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - chunk: payloads chunk to send.
    ///   - completion: completion callback to inform the class about the result of the send operation.
    func asyncTransport(_ transport: AsyncTransport,
                        canSendPayloadsChunk chunk: AsyncTransport.Chunk,
                        completion: ((Error?) -> Void))
    
    /// Received when an error has occurred handling data inside the class.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - error: error occurred.
    func asyncTransport(_ transport: AsyncTransport,
                        didFailWithError error: Error)
    
    /// This method is called to inform the delegate when a chunk of payloads failed to be
    /// sent.
    ///
    /// - Parameters:
    ///   - transport: transport.
    ///   - error: error occurred, typically a network related one.
    ///   - payloads: events marked for retry attempt (tuple with id of the event, attempt)
    ///   - discardIds: discarded events, will be removed from cache and never sent.
    func asyncTransport(_ transport: AsyncTransport,
                        didFailSendingChunkWithError error: Error,
                        willRetry payloads: [(String, Int)],
                        willDiscard discardIds: Set<String>)
    
    /// Called when a chunk of data is marked as sent.
    ///
    /// - Parameters:
    ///   - transport: transport.
    ///   - sentEventIDs: event identifiers sent successfully.
    func asyncTransport(_ transport: AsyncTransport,
                        sentEventIDs: Set<String>)
    
    /// Called when a trim due to buffer size limit reached occour.
    ///
    /// - Parameters:
    ///   - transport: transport.
    ///   - discardedEventsFromBuffer: number of events discarded from the oldest.
    func asyncTransport(_ transport: AsyncTransport,
                        discardedEventsFromBuffer: Int64)
    
}

// MARK: - Optional Delegate Methods

extension AsyncTransportDelegate {
    
    public func asyncTransport(_ transport: AsyncTransport, didFailWithError error: Error) {}
    public func asyncTransport(_ transport: AsyncTransport,
                        didFailSendingChunkWithError error: Error,
                        willRetry payloads: [(String, Int)],
                        willDiscard discardIds: Set<String>) {}
    public func asyncTransport(_ transport: AsyncTransport,
                        sentEventIDs: Set<String>) {}
    public func asyncTransport(_ transport: AsyncTransport,
                        discardedEventsFromBuffer: Int64) {}
    
}
