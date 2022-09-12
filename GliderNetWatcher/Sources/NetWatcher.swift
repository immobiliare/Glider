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

/// The `NetWatcher` class is used to perform networking monitoring inside your app.
/// It will intercepts any call coming from a third party library and URLSession too.
/// Events intercepted are classic Glider's `Event` class with attached `object` of type
/// `NetworkEvent`.
/// The `NetworkEvent` contains all the relevant information about the request and its response.
///
/// The following code allows you to intercept all the traffic of your app saving in a convenient
/// database SQLite3.
///
/// ```swift
///  // Setup the configuration
///  let archiveURL = URL(fileURLWithPath: ".../sniffed_network.sqlite")
///  let archiveConfig = NetArchiveTransport.Configuration(location: .fileURL(archiveURL))
///  NetWatcher.shared.setConfiguration(watcherConfig)
///
///  // Activate global sniffer
///  NetWatcher.shared.captureGlobally(true)
/// ```
///
/// When you want to stop capturing traffic uses the `NetWatcher.shared.captureGlobally(false)`.
///
/// To read an event:
///
/// ```swift
/// if let request = receivedEvent.networkEvent() {
///     print("Network request to \(request.url) ended as \(request.statusCode)
/// }
/// ```
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
    
    /// Capture the traffic of a specified `URLSessionConfiguration`.
    ///
    /// - Parameters:
    ///   - enabled: `true` to enable, `false` to disable recording.
    ///   - configuration: configuration to record.
    /// - Returns: `Bool`
    @discardableResult
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
    
    /// Record an event coming from `LoggerURLProtocol` instance.
    ///
    /// - Parameter event: event received.
    private func record(_ event: Event) {
        guard let config = config else {
            return
        }

        let isSync = config.isSynchronous
        let transports = config.transports

        let mainExecutor = executorForQueue(config.queue, synchronous: isSync)
        mainExecutor { [event, transports] in
            for recorder in transports{
                let recorderExecutor = self.executorForQueue(recorder.queue, synchronous: isSync)
                recorderExecutor {
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
