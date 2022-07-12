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
public final class NetworkLogger: NSObject {
    
    // MARK: - Public Properties
    
    /// Shared instance.
    public static var current = NetworkLogger()

    /// By default, empty.
    public var ignoredHosts = Set<String>()
    
    /// Where the network events are redirected.
    public var destinationLog: Log?
    
    /// Your own delegate class where the methods are forwarded after logged.
    public var delegate: URLSessionDelegate? {
        set {
            self.actualDelegate = newValue
            self.taskDelegate = newValue as? URLSessionTaskDelegate
        }
        get {
            self.actualDelegate
        }
    }
    
    // MARK: - Private Properties
    
    private var actualDelegate: URLSessionDelegate?
    private var taskDelegate: URLSessionTaskDelegate?
    private var urlSessionDataDelegate: URLSessionDataDelegate? {
        actualDelegate as? URLSessionDataDelegate
    }
    private var interceptedSelectors: Set<Selector> = []

    // MARK: - Initialization
    
    /// Initialize a new instance of the network logger you can use as `URLSessionDelegate`'s' proxy instance.
    ///
    /// - Parameters:
    ///   - destinationLog: destination log, when not specified a default console log with table formatter is used.
    ///   - delegate: The "actual" session delegate, strongly retained.
    public init(destinationLog: Log? = nil, delegate: URLSessionDelegate? = nil) {
        super.init()

        self.destinationLog = destinationLog ?? NetworkLogger.defaultLogDestination()
        self.delegate = delegate
        self.interceptedSelectors = [
            #selector(URLSessionDataDelegate.urlSession(_:dataTask:didReceive:)),
            #selector(URLSessionTaskDelegate.urlSession(_:task:didCompleteWithError:)),
            #selector(URLSessionDataDelegate.urlSession(_:dataTask:didReceive:completionHandler:)),
            #selector(URLSessionTaskDelegate.urlSession(_:task:didFinishCollecting:))
        ]
    }
    
    // MARK: - Public Functions
    
    /// Enables automatic registration of `NetworkLogger` for any new custom `URLSession` instance created.
    /// After calling this method, every time you initialize a `URLSession` using `init(configuration:delegate:delegateQueue:))`
    /// method, the delegate will automatically get replaced with a `NetworkLogger` that logs all the
    /// needed events and forwards the methods to your original delegate.
    ///
    /// - Parameter destinationLog: destination log.
    public static func captureTrafficFromURLSessions(toLog destinationLog: Log? = nil, delegate: URLSessionDelegate? = nil) {
        NetworkLogger.current.destinationLog = destinationLog
        NetworkLogger.current.delegate = delegate

        if let lhs = class_getClassMethod(URLSession.self, #selector(URLSession.init(configuration:delegate:delegateQueue:))),
           let rhs = class_getClassMethod(URLSession.self, #selector(URLSession.custom_init(configuration:delegate:delegateQueue:))) {
            method_exchangeImplementations(lhs, rhs)
        }
    }
    
    /// Capture global network traffic on `URLSession.default` instance.
    ///
    /// - Parameters:
    ///   - enabled: `true` to enable capture, `false` to disable.
    ///   - destinationLog: destination log, if `nil` a default console-based log instance is created for you.
    public static func captureGlobalTraffic(enabled: Bool, toLog destinationLog: Log? = nil) {
      /*  if enabled {
            URLProtocol.registerClass(CustomHTTPProtocol.self)
        } else {
            URLProtocol.unregisterClass(CustomHTTPProtocol.self)
        }*/
    }
    
    // MARK: - Private Functions (Helper)
    
    /// Create the default log destination for networking logs.
    ///
    /// - Returns: `Log`
    private static func defaultLogDestination() -> Log {
        Log {
            $0.transports = [
                ConsoleTransport({ console in
                    console.formatters = [TableFormatter(messageFields: [
                        .message()
                    ], tableFields: [
                        .extra(keys: ["url"])
                    ])]
                })
            ]
        }
    }
    
    // MARK: - Private Functions (Logging)
    
    fileprivate func logTask(_ task: URLSessionTask, didCompleteWithError error: Error?, session: URLSession? = nil) {
        
    }
    
    fileprivate func logTask(_ task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        
    }
    
    fileprivate func logDataTask(_ dataTask: URLSessionDataTask, didReceive response: URLResponse) {

    }
    
    fileprivate func logDataTask(_ dataTask: URLSessionDataTask, didReceive data: Data) {

    }
    
    // MARK: - Proxy
    
    public override func responds(to aSelector: Selector!) -> Bool {
        if interceptedSelectors.contains(aSelector) {
            return true
        }
        return (actualDelegate?.responds(to: aSelector) ?? false) || super.responds(to: aSelector)
    }

    public override func forwardingTarget(for selector: Selector!) -> Any? {
        interceptedSelectors.contains(selector) ? nil : actualDelegate
    }
    
}

// MARK: - URLSessionTaskDelegate

extension NetworkLogger: URLSessionTaskDelegate {
        
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        logTask(task, didCompleteWithError: error)
        taskDelegate?.urlSession?(session, task: task, didCompleteWithError: error)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        logTask(task, didFinishCollecting: metrics)
        taskDelegate?.urlSession?(session, task: task, didFinishCollecting: metrics)
    }

}

// MARK: - URLSessionDataDelegate

extension NetworkLogger: URLSessionDataDelegate {

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                           completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        logDataTask(dataTask, didReceive: response)
        
        guard actualDelegate?.responds(to: #selector(URLSessionDataDelegate.urlSession(_:dataTask:didReceive:completionHandler:))) ?? false else {
            completionHandler(.allow)
            return
        }
        
        urlSessionDataDelegate?.urlSession?(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        logDataTask(dataTask, didReceive: data)
        urlSessionDataDelegate?.urlSession?(session, dataTask: dataTask, didReceive: data)
    }
    
}
