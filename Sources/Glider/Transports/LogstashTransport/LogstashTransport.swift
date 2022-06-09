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
import Network

open class LogstashTransport: Transport, AsyncTransportDelegate {
    public typealias DispatchedChunk = (event: Event, error: Error?)

    // MARK: - Public Properties
    
    /// GCD queue.
    public var queue: DispatchQueue?
    
    /// Configuration used.
    public let configuration: Configuration
    
    /// Delegate class.
    public weak var delegate: LogstashTransportDelegate?
    
    // MARK: - Private Properties
    
    /// Socket queue.
    private let socketQueue = OperationQueue()
    
    /// URLSession to use.
    private var session: URLSession?
    
    /// Session delegate.
    private var sessionDelegate: LogstashURLSessionDelegate?

    /// Async transporter.
    private var asyncTransport: AsyncTransport?
    
    // MARK: - Initialization
    
    /// Initialize a new logstash transport.
    ///
    /// - Parameters:
    ///   - host: hostname.
    ///   - port: port number.
    ///   - delegate: delegate for events.
    ///   - builder: builder to configure extra options.
    public init(host: String, port: Int,
                delegate: LogstashTransportDelegate? = nil,
                _ builder: ((inout Configuration) -> Void)? = nil) throws {
        self.configuration = Configuration(host: host, port: port, builder)
        self.delegate = delegate
        self.queue = configuration.queue
        
        self.asyncTransport = try AsyncTransport(delegate: self,
                                                 configuration: configuration.asyncTransportConfiguration)
        self.sessionDelegate = LogstashURLSessionDelegate(transport: self)
        self.session = URLSession(configuration: .ephemeral,
                                  delegate: self.sessionDelegate,
                                  delegateQueue: socketQueue)
    }
    
    // MARK: - Public Functions
    
    /// Cancel all active tasks, invalidate the session and create the new one.
    open func reset() {
        session?.invalidateAndCancel()
        session = URLSession(configuration: .ephemeral,
                             delegate: sessionDelegate,
                             delegateQueue: socketQueue)
    }
    
    
    // MARK: - Conformance
    
    public func asyncTransport(_ transport: AsyncTransport,
                               canSendPayloadsChunk chunk: AsyncTransport.Chunk,
                               completion: ((Error?) -> Void)) {
        guard let session = session, let queue = queue else {
            return
        }

        let task = session.streamTask(withHostName: configuration.host, port: configuration.port)
        if !configuration.allowUntrustedServer {
            task.startSecureConnection()
        }
        
        let dispatchGroup = DispatchGroup()
        var sendStatus = [DispatchedChunk]()
        var countFailed = 0
        var countSucceded = 0
        
        for item in chunk {
            guard let messageData = item.message?.asData() else {
                continue
            }
            
            dispatchGroup.enter()

            task.write(messageData, timeout: configuration.timeout) { [weak self] error in
                guard let _ = self else {
                    dispatchGroup.leave()
                    return
                }
                
                queue.async(group: dispatchGroup) {
                    sendStatus.append( (item.event, error))
                    if error != nil {
                        countFailed += 1
                    } else {
                        countSucceded += 1
                    }
                }
            }
        }
        
        task.resume()
        
        dispatchGroup.notify(queue: queue) { [weak self] in
            task.closeRead()
            task.closeWrite()
            
            self?.delegate?.logstashTransport(self!,
                                              didFinishSendingChunk: sendStatus,
                                              countFailed: countFailed,
                                              countSucceded: countSucceded)
        }
    }
    
    public func record(event: Event) -> Bool {
        asyncTransport?.record(event: event) ?? false
    }
    
}

// MARK: - Configuration

extension LogstashTransport {
    
    public struct Configuration {
        
        /// Allow untrusted connection to server.
        /// By default is set to `false`.
        public var allowUntrustedServer = false
        
        /// Host URL.
        public var host: String
        
        /// Connection port.
        public var port: Int
        
        /// Dispatch queue where the record happens.
        public var queue = DispatchQueue(label: "Glider.\(UUID().uuidString)")
        
        /// Connection timeout.
        /// By default is set to 5 seconds.
        public var timeout: TimeInterval = 5
        
        /// Delegate class.
        public weak var delegate: LogstashTransportDelegate?
        
        /// Formatters set.
        ///
        /// NOTE:
        /// This is a derivate properties of the `AsyncTransport.Configuration`,
        /// it will set automatically the underlying AsyncTransport.Configuration.
        public var formatters: [EventFormatter] {
            set { asyncTransportConfiguration.formatters = newValue }
            get { asyncTransportConfiguration.formatters }
        }
        
        /// Limit cap for stored message.
        ///
        /// NOTE:
        /// This is a derivate properties of the `AsyncTransport.Configuration`,
        /// it will set automatically the underlying AsyncTransport.Configuration.
        public var maxEntries: Int {
            set { asyncTransportConfiguration.maxRetries = newValue }
            get { asyncTransportConfiguration.maxRetries }
        }

        /// Size of the chunks (number of payloads) sent at each dispatch event.
        ///
        /// NOTE:
        /// This is a derivate properties of the `AsyncTransport.Configuration`,
        /// it will set automatically the underlying AsyncTransport.Configuration.
        public var chunkSize: Int {
            set { asyncTransportConfiguration.chunksSize = newValue }
            get { asyncTransportConfiguration.chunksSize }
        }
        
        /// Automatic interval for flushing data in buffer.
        ///
        /// NOTE:
        /// This is a derivate properties of the `AsyncTransport.Configuration`,
        /// it will set automatically the underlying AsyncTransport.Configuration.
        public var autoFlushInterval: TimeInterval? {
            set { asyncTransportConfiguration.autoFlushInterval = newValue }
            get { asyncTransportConfiguration.autoFlushInterval }
        }

        // MARK: - Private Properties
        
        /// Async transport used to configure the underlying service.
        /// By default a default `AsyncTransport` class with default settings is used.
        internal var asyncTransportConfiguration: AsyncTransport.Configuration

        public init(host: String, port: Int, _ builder: ((inout Configuration) -> Void)?) {
            self.host = host
            self.port = port
            self.asyncTransportConfiguration = .init()
            builder?(&self)
        }
        
    }
    
}

// MARK: - LogstashURLSessionDelegate

extension LogstashTransport {
    
    private class LogstashURLSessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionStreamDelegate {
        
        // MARK: - Private Properties
        
        /// Parent transport.
        fileprivate weak var transport: LogstashTransport?
        
        // MARK: - Initialization
        
        init(transport: LogstashTransport?) {
            self.transport = transport
            super.init()
        }
        
        func urlSession(_ session: URLSession,
                        didReceive challenge: URLAuthenticationChallenge,
                        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            
            if  challenge.protectionSpace.host == transport?.configuration.host,
                let trust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: trust)
                completionHandler(.useCredential, credential)
            } else {
                transport?.delegate?.logstashTransport(transport!, didFailTrustingService: transport!.configuration.host)
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }
    
}

// MARK: - LogstashTransportDelegate

public protocol LogstashTransportDelegate: AnyObject {
    
    /// Event triggered when transport fails to authenticate to remote server.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - host: host service.
    func logstashTransport(_ transport: LogstashTransport,
                           didFailTrustingService host: String)
    
    /// Event triggered when a chunk of data is sent.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - chunk: the result of chunk sending operation, each event with the associated optional error if failed.
    ///   - countFailed: count failed sent.
    ///   - countSucceded: count succeded sent.
    func logstashTransport(_ transport: LogstashTransport,
                           didFinishSendingChunk chunk: [LogstashTransport.DispatchedChunk],
                           countFailed: Int, countSucceded: Int)
    
}
