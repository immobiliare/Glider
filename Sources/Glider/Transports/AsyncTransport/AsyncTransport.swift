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
/// It works like `ThrottledTransport` but it can store logs locally before sending to the network
/// and can retry unsent payloads.
public class AsyncTransport: Transport {
    
    // MARK: - Public Properties
    
    public var queue: DispatchQueue?
    
    /// Data formatters.
    public let formatters: [EventFormatter]
    
    /// Flush interval.
    public let flushInterval: TimeInterval?
    
    /// Size of the buffer.
    public var bufferSize: Int
    
    public let blockSize: Int
    
    // MARK: - Private Properties
    
    /// Last flush date of the buffer.
    private var lastFlushDate: Date?
    
    /// Auto flush timer.
    private var flushTimer: Timer?
    
    
    // MARK: - Initialization
    
    public init(bufferSize: Int,
                blockSize: Int,
                flushInterval: TimeInterval? = nil,
                formatters: [EventFormatter],
                queue: DispatchQueue? = nil) {
        self.formatters = formatters
        self.bufferSize = bufferSize
        self.flushInterval = flushInterval
        self.blockSize = blockSize
        self.queue = queue ?? DispatchQueue(label: String(describing: type(of: self)))
        
        setupAutoFlushIntervalIfNeeded()
    }
    
    // MARK: - Conformance

    public func record(event: Event) -> Bool {
        let message = formatters.format(event: event)
        
        let payload = (event, message)
        
        return true
    }
    
    // MARK: - Private Functions
    
    private func setupAutoFlushIntervalIfNeeded() {
        /*guard let flushInterval = flushInterval else {
            return
        }
        
        let timer = Timer(timeInterval: flushInterval,
                          target: self,
                          selector: #selector(tick),
                          userInfo: nil,
                          repeats: true)
        
        DispatchQueue.main.async {
            RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
        }
        
        self.flushTimer = timer*/
    }
    
    @objc
    private func tick() {
        flush()
    }
    
    private func flush() {
        queue?.sync {
           
            
            
            
        }
    }
    
    
}

/*
public protocol AsyncTransportDelegate: AnyObject {
    
    /// This method is called to allow a client of the AsyncTransportDelegate to
    /// send a bulk of payloads to a service. Send operation happens asynchronouly
    /// and you should call completion block to inform if there are any unsent
    /// payloads you want to be re-added to the batch of
    ///
    /// - Parameters:
    ///   - transport: <#transport description#>
    ///   - payloads: <#payloads description#>
    ///   - completion: <#completion description#>
    func asyncTransport(_ transport: AsyncTransport, readyToSendPayloads payloads: [Payload],
                        completion: ((Void) -> [Payload]))
    
}
*/
