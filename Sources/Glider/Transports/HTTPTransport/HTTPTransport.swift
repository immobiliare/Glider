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

open class HTTPTransport: Transport {
    
    // MARK: - Public Properties
    
    /// GCD queue.
    public var queue: DispatchQueue?
    
    /// Configuration used to prepare the transport.
    public let configuration: Configuration
    
    /// Count running operations.
    public var runningOperations: Int {
        networkQueue.operationCount
    }
    
    /// Delegate.
    public weak var delegate: HTTPTransportDelegate?
    
    // MARK: - Private Properties
    
    /// Operation Queue
    private var networkQueue = OperationQueue()
    
    /// Async transporter.
    private var asyncTransport: AsyncTransport
    
    // MARK: - Initialization
    
    /// Initialize a new HTTP Transport for generic HTTP log sends.
    /// - Parameter builder: configuration builder callback.
    public init(_ builder: ((inout Configuration) -> Void)? = nil) throws {
        self.configuration = try Configuration(builder)
        self.asyncTransport = configuration.asyncTransport
        self.delegate = configuration.delegate
                
        defer {
            self.networkQueue.maxConcurrentOperationCount = configuration.maxConcurrentOperationCount
        }
    }
    
    // MARK: - Conformance
    
    public func record(event: Event) -> Bool {
        true
    }
    
    
}

// MARK: - HTTPTransport.Configuration

extension HTTPTransport {
    
    public struct Configuration {
        
        /// The value in this property affects only the operations that
        /// the current queue has executing at the same time.
        ///
        /// By default is set to 3.
        public var maxConcurrentOperationCount: Int = 3
        
        /// URL Session used to send data.
        /// By default `.default` is used
        public var session: URLSession
        
        /// Async transport used to configure the underlying service.
        /// By default a default `AsyncTransport` class with default settings is used.
        public var asyncTransport: AsyncTransport
        
        /// Delegate for HTTPTransport messages.
        public weak var delegate: HTTPTransportDelegate?
        
        /// GCD Queue.
        public var queue = DispatchQueue(label: "Glider.\(UUID().uuidString)")

        // MARK: - Initialization
        
        /// Initialize a new default `HTTPTransport` instance.
        public init(_ builder: ((inout Configuration) -> Void)?) throws {
            self.asyncTransport = try AsyncTransport({ _ in })
            self.session = URLSession(configuration: .default)
            builder?(&self)
        }
        
    }
    
}
