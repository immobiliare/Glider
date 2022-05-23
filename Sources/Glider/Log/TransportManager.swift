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

/// This class provide the low-level interface for accepting log messages.
public class TransportManager {
    
    // MARK: - Private Properties
    
    /// Identify type of dispatch queue.
    /// Typically you want to set if to `false` in production and `true` in development.
    /// Synchronous mode is helpful while debugging, as it ensures that logs are always up-to-date.
    /// By default is set to `false`.
    ///
    /// DISCUSSION:
    /// when debug breakpoints are hit.
    /// However, synchronous mode can have a negative influence on performance and is
    /// therefore not recommended for use in production code.
    private let isSynchronous: Bool
    
    /// Serialized strategies. If not set the default's `TransportManager` is used instead.
    internal private(set) var serializedStrategies: SerializationStrategies
        
    /// This is the dispatch queue which make in order the payload received from different channels.
    private let acceptQueue: DispatchQueue
    
    /// Used to decide whether a given event should be passed along to the receiver
    /// recorders. If at least one of the filter specified (executed in order) return `false`
    /// from `shouldWrite()` function payload will be silently ignored when being processed.
    internal var filters = [TransportFilter]()
    
    /// List of transports associated with the log.
    /// Transports are the container where events are stored.
    internal var transports = [Transport]()
    
    // MARK: - Initialization
    
    /// Initialize a new transport manager using given configuration.
    ///
    /// - Parameter configuration: configuration.
    internal init(configuration: Log.Configuration) {
        self.serializedStrategies = configuration.serializationStrategies
        self.isSynchronous = configuration.isSynchronous
        self.acceptQueue = configuration.acceptQueue
        self.filters = configuration.filters
        self.transports = configuration.transports
    }
    
    // MARK: - Internal Functions
    
    /// Record a new event to underlying transports.
    ///
    /// - Parameter event: event to log.
    internal func write(_ event: inout Event) {
        // serialize the assigned object, if any.
        event.serializeObjectIfNeeded(withTransportManager: self)

        
        let mainExecutor = executorForQueue(acceptQueue, synchronous: isSynchronous)
        mainExecutor { [event, filters, transports] in
            // Verify if payload pass the filters check (if set).
            guard filters.canAcceptEvent(event) else {
                return
            }
            
            for recorder in transports {
                if let queue = recorder.queue {
                    let recorderExecutor = self.executorForQueue(queue, synchronous: self.isSynchronous)
                    recorderExecutor {
                        recorder.record(event: event)
                    }
                } else {
                    recorder.record(event: event)
                }
            }
        }
    }
    
    // MARK: - Private Functions
    
    /// Create dispatch queue.
    ///
    /// - Parameters:
    ///   - queue: queue
    ///   - synchronous: `true` for synchronous.
    /// - Returns: Escaping function.
    private func executorForQueue(_ queue: DispatchQueue, synchronous: Bool) -> (@escaping () -> Void) -> Void {
        let executor: (@escaping () -> Void) -> Void = { block in
            if synchronous {
                return queue.sync(execute: block)
            } else {
                return queue.async(execute: block)
            }
        }
        return executor
    }
    
}

// MARK: - EventFilter Array Extension

extension Array where Element == TransportFilter {
    
    /// Return true if passed event can be recorded using filters of the array.
    ///
    /// - Parameter event: event to log.
    /// - Returns: Bool
    fileprivate func canAcceptEvent(_ event: Event) -> Bool {
        guard isEmpty == false else { return true }
        
        if let _ = first(where: { $0.shouldAccept(event) == false }) {
            return false
        }
        
        return true
    }
    
}
