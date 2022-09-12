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

/// This class provide the low-level interface for accepting log messages.
/// You will never interact with this class.
public final class TransportManager {
    
    // MARK: - Private Properties
    
    /// Identify the dispatch queue used to receive messages.
    ///
    /// Typically you want to set if to `false` in production and `true` in development.
    /// Synchronous mode is helpful while debugging, as it ensures that logs are always up-to-date.
    /// when debug breakpoints are hit.
    ///
    /// However, synchronous mode can have a negative influence on performance and is
    /// therefore not recommended for use in production code.
    ///
    /// By default is set to `false`.
    private let isSynchronous: Bool
    
    /// Serialized strategies for object encoding.
    ///
    /// If not set the default's `TransportManager` is used instead.
    internal private(set) var serializedStrategies: SerializationStrategies
        
    /// This is the dispatch queue which make in order the payload received from different channels.
    private let acceptQueue = DispatchQueue(label: "glider.transport-manager.acceptqueue", attributes: [])
    
    /// Used to decide whether a given event should be passed along to the receiver
    /// recorders.
    ///
    /// If at least one of the filter specified (executed in order) return `false`
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
        self.filters = configuration.filters
        self.transports = configuration.transports
    }
    
    // MARK: - Internal Functions
    
    internal func write(_ event: inout Event) {
        // serialize the assigned object, if any.
        event.serializeObjectIfNeeded(withTransportManager: self)
        // dispatch to transports
        writeToTransports(event)
    }
    
    /// Record a new event to underlying transports.
    ///
    /// - Parameter event: event to log.
    internal func writeToTransports(_ event: Event) {
        let acceptDispatcher = dispatcherForQueue(acceptQueue, synchronous: isSynchronous)
        acceptDispatcher { [weak self] in
            guard let self = self else {
                return
            }
            
            guard self.filters.canAcceptEvent(event) else {
                return // event ignored by the filters
            }
            
            for transport in self.transports {
                let recordDispatcher = self.dispatcherForQueue(transport.queue, synchronous: self.isSynchronous)
                recordDispatcher {
                    if transport.isEnabled && event.level.isAcceptedWithMinimumLevelSet(minLevel: transport.minimumAcceptedLevel) {
                        transport.record(event: event)
                    }
                }
            }
            
        }
    }
    
    // MARK: - Private Functions
    
    /// Call the dispatch queue `async` or `sync` method based upon configuration settings.
    /// It's used to perform synchronous or asynchronous logging.
    ///
    /// - Parameters:
    ///   - queue: target queue to call.
    ///   - synchronous: `true` to perform synchronous call, `false` to make asynchronous call (typically on production).
    /// - Returns:`(@escaping () -> Void) -> Void`
    private func dispatcherForQueue(_ queue: DispatchQueue, synchronous: Bool) -> (@escaping () -> Void) -> Void {
        let dispatcher: (@escaping () -> Void) -> Void = { block in
            if synchronous {
                return queue.sync(execute: block)
            } else {
                return queue.async(execute: block)
            }
        }
        return dispatcher
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
        // swiftlint:disable unused_optional_binding
        if let _ = first(where: { $0.shouldAccept(event) == false }) {
            return false
        }
        
        return true
    }
    
}
