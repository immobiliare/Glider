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
import Glider

/// The `NetworkLogger` class is used to perform networking monitoring of your app.
/// It will intercepts any call coming from a third party library like RealHTTP or Alamofire
/// and URLSession too. It allows to specify a `Log` instance where the logs are redirected to.
public class NetWatcher {
  
    // MARK: - Public Properties
    
    /// Singleton instance.
    public static let shared = NetWatcher()
    
    /// Delegate to receive events from the singleton.
    public weak var delegate: NetWatcherDelegate?
    
    /// Active configuration.
    /// The default configuration store data in memory with a limit of the last 100 network calls.
    public private(set) var config: Config?
    
    /// Return `true` if recording globally or at least one configuration is on.
    public private(set) var isActive: Bool = false
    
    /// Hosts that will be ignored from being recorded.
    public var ignoredHosts: [String] {
        get { LoggerURLProtocol.ignoredHosts }
        set { LoggerURLProtocol.ignoredHosts = newValue }
    }
    
    // MARK: - Initialization
    
    private init() { }
    
    // MARK: - Public Functions
    
    /// Modify the configuration.
    ///
    /// NOTE:
    /// You should never call it while recording is in progress.
    /// In this case no changes are applied.
    ///
    /// - Parameter configuration: new configuration
    @discardableResult
    public func setConfiguration(_ config: Config) -> Bool {
        guard isActive == false else {
            return false
        }
        
        self.config = config
        self.ignoredHosts = config.ignoredHosts
        return true
    }
    
    /// Capture network traffic globally regardless specified `URLSession` instance.
    ///
    /// - Parameter enabled: `true` to activate the configuration
    public func captureGlobally(_ enabled: Bool) {
        if enabled && isActive == false {
            URLProtocol.registerClass(LoggerURLProtocol.self)
            isActive = true
        } else if enabled == false && isActive {
            URLProtocol.unregisterClass(LoggerURLProtocol.self)
            isActive = false
        }
        
    }
    
    @discardableResult
    /// Capture the traffic of a specified `URLSessionConfiguration`.
    ///
    /// - Parameters:
    ///   - enabled: `true` to enable, `false` to disable recording.
    ///   - configuration: configuration to record.
    /// - Returns: `Bool`
    public func capture(_ enabled: Bool, forSessionConfiguration configuration: URLSessionConfiguration) -> Bool {
        guard isActive == false else {
            return false
        }
        
        var urlProtocolClasses = configuration.protocolClasses
        guard urlProtocolClasses != nil else {
            return false
        }
        
        let index = urlProtocolClasses?.firstIndex(where: { (obj) -> Bool in
            if obj == LoggerURLProtocol.self {
                return true
            }
            return false
        })
        
        if enabled && index == nil {
            urlProtocolClasses!.insert(LoggerURLProtocol.self, at: 0)
        } else if !enabled && index != nil{
            urlProtocolClasses!.remove(at: index!)
        }
        configuration.protocolClasses = urlProtocolClasses
        return true
    }
    
    // MARK: - Internal Function
    
    /// Record a new network event.
    ///
    /// - Parameter networkLog: event to log.
    internal func record(_ networkLog: NetworkEvent?) {
        guard let networkLog = networkLog else {
            return
        }

        let event = Event(message: "Network Request \(networkLog.id)", object: networkLog)
        record(event)
    }
    
    // MARK: - Private Function
    
    private func record(_ event: Event) {
        guard let config = config else {
            return
        }

        let isSync = config.isSynchronous
        let transports = config.transports

        let mainExecutor = executorForQueue(config.queue, synchronous: isSync)
        mainExecutor { [event, transports] in
            for recorder in transports{
                if let queue = recorder.queue {
                    let recorderExecutor = self.executorForQueue(queue, synchronous: isSync)
                    recorderExecutor {
                        recorder.record(event: event)
                    }
                } else {
                    recorder.record(event: event)
                }
            }
        }
    }
    
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
