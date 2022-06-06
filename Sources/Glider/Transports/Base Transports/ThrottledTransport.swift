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

/// The throttled transport is a tiny but thread-safe logger with a buffering and retrying mechanism for iOS.
/// Buffer is a limit cap when reached call the flush mechanism. You can also set a time interval to
/// auto flush the content of the buffer regardless the number of currently stored payloads.
///
/// Your own implementation must override the `record(transport:completion:)` to record a group of events.
public class ThrottledTransport: Transport {
    public typealias Completion = ((Error?) -> Void)
    public typealias Payload = (Event, SerializableData?)

    // MARK: - Public Properties
    
    /// Queue used to access to the buffer.
    public var queue: DispatchQueue?

    /// Configuration
    public let configuration: Configuration
    
    /// Delegate for events.
    public var delegate: ThrottledTransportDelegate?
    
    /// Pending payloads contained into the buffer.
    public var pendingPayloads: [Payload] {
        queue?.sync {
            buffer
        } ?? []
    }
    
    // MARK: - Private Properties
    
    /// Timer used to auto-flush at intervals.
    private var timer: Timer?
    
    /// Last flush date of the buffer.
    private var lastFlushDate: Date?
    
    /// Buffer container.
    private var buffer = [Payload]()
    
    private var now: Date {
        Date()
    }
        
    // MARK: - Initialization
    
    /// Initialize `ThrottledTransport` with given configuration.
    ///
    /// - Parameter builder: configuration callback.
    public init(_ builder: ((inout Configuration) -> Void)) {
        self.configuration = Configuration(builder)
        
        self.buffer.reserveCapacity(configuration.bufferSize) // Reserve capacity to optimize storage in memory.
        self.delegate = configuration.delegate
        
        self.queue = configuration.queue
        queue!.sync { [weak self] in
            self?.setupAutoFlushIntervalIfNeeded()
        }
    }
    
    /// Perform manual flush.
    public func flush() {
        self.lastFlushDate = Date()
        queue!.async {
            self.flush(reason: .byUser)
        }
    }
    
    // MARK: - Overridable Functions
    
    open func record(throttledEvents events: [Payload], reason: FlushReason, completion: Completion?) {
        // Implement your own action to send buffer's payloads to the transport implementation.
    }
    
    // MARK: - Conformance
    
    public func record(event: Event) -> Bool {
        queue!.async { [weak self] in
            guard let self = self else { return }
            
            let message = self.configuration.formatters.format(event: event)
            
            self.buffer.append( (event, message) )
            if self.buffer.count >= self.configuration.bufferSize {
                self.flush(reason: .byBufferSize)
            }
        }
        
        return true
    }
    
    /// Initialize the autoflush interval.
    private func setupAutoFlushIntervalIfNeeded() {
        guard let flushInterval = configuration.flushInterval else { return }
        
        if #available(iOS 10.0, *) {
            dispatchPrecondition(condition: .onQueue(queue!))
        }

        self.lastFlushDate = Date()
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
    
    /// Called by timer.
    @objc
    private func tick() {
        self.lastFlushDate = Date()        
        queue!.async {
            self.flush(reason: .byInterval)
        }
    }
    
    /// The flush call is called when buffer reached the cap size or timer is triggered.
    private func flush(reason: FlushReason) {
        if #available(iOS 10.0, *) {
            dispatchPrecondition(condition: .onQueue(queue!))
        }
        
        if buffer.isEmpty {
            return
        }
        
        let payloadsCount = min(buffer.count, configuration.bufferSize)
        let newPayloadsBuffer = Array(buffer.dropFirst(payloadsCount))
        let droppedPayloads = Array(buffer[0..<payloadsCount])
        self.buffer = newPayloadsBuffer
        
        DispatchQueue.main.async { [weak self]  in
            guard let self = self else { return }

            self.record(throttledEvents: droppedPayloads, reason: reason, completion: nil)
            self.delegate?.record(self, events: droppedPayloads, reason: reason, nil)
        }
    }
    
}

// MARK: - Configuration

extension ThrottledTransport {
    
    public struct Configuration {
        
        // MARK: - Public Properties
        
        /// Size of the buffer.
        /// Keep in mind: a big size may impact to the memory. Tiny sizes may impact on storage service load.
        ///
        /// By default is set to 500.
        public var bufferSize: Int = 500
        
        /// Auto flush interval, if `nil` no autoflush is made.
        /// If specified this is the interval used to autoflush.
        /// By default is not set, the only constraint is the size of the buffer.
        public var flushInterval: TimeInterval?
        
        /// It will receive chunk of payloads to register.
        public weak var delegate: ThrottledTransportDelegate?
        
        /// Queue used to access to the buffer.
        public var queue = DispatchQueue(label: "Glider.\(UUID().uuidString)")

        /// Formatters used to format events into messages.
        public var formatters = [EventFormatter]()
        
        // MARK: - Initialization
        
        /// Initialize a new configuration for `ThrottledTransport`.
        ///
        /// - Parameter builder: builder function.
        public init(_ builder: ((inout Configuration) -> Void)) {
            builder(&self)
        }
        
    }
    
}

// MARK: - BufferedTransportDelegate

public protocol ThrottledTransportDelegate: AnyObject {
    /// Called when a chunk of data coming from a buffered transport is ready to be saved.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - events: chunk of data you can save.
    ///   - reason: what reason trigger the event.
    ///   - completion: completion calback.
    func record(_ transport: ThrottledTransport,
                events: [ThrottledTransport.Payload], reason: ThrottledTransport.FlushReason,
                _ completion: ThrottledTransport.Completion?)
    
}

extension ThrottledTransport {
    
    /// Describe what events triggere the delegate method where you
    /// receive the group of events.
    ///
    /// - `byInterval`: flush interval passed, any events collected in buffer beside the buffer limit is sent
    /// - `byBufferSize`: events in buffer reached the max size so they are sent.
    /// - `byUser`: manual flush.
    public enum FlushReason: String {
        case byInterval
        case byBufferSize
        case byUser
    }
    
}
