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
public class NetworkLogger: URLProtocol {
  
    // MARK: - Private Properties
    
    private var urlTask: URLSessionDataTask?
    
    private var logItem: NetworkLogItem?

    private let serialQueue = DispatchQueue(label: "com.glider.networklogger.serialqueue")

    private lazy var session: URLSession = URLSession(configuration: URLSessionConfiguration.default,
                                                      delegate: self, delegateQueue: nil)

    static private var ignoreDomains: [String]?

    // MARK: - Lifecycle
    
    deinit {
        clear()
    }
    
    // MARK: - Public Functions
    
    public class func enable(in configuration: URLSessionConfiguration) {
        configuration.protocolClasses?.insert(NetworkLogger.self, at: 0)
    }
    
    public class func register() {
        URLProtocol.registerClass(self)
    }

    public class func unregister() {
        URLProtocol.unregisterClass(self)
    }
    
    // MARK: - URLProtocol
    
    open override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url, let scheme = url.scheme else {
            return false
        }
        
        guard !isIgnore(with: url) else {
            return false
        }
        
        return ["http", "https"].contains(scheme) && self.property(forKey: Keys.request, in: request)  == nil
    }
    
    open override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    open override func startLoading() {
        if let _ = urlTask { return }
        guard let urlRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest,
                logItem == nil else {
            return
        }

        logItem = NetworkLogItem(request: urlRequest as URLRequest)
        NetworkLogger.setProperty(true, forKey: Keys.request, in: urlRequest)
        
        urlTask = session.dataTask(with: request)
        urlTask?.resume()
    }

    open override func stopLoading() {
        serialQueue.sync { [weak self] in
            self?.urlTask?.cancel()
            self?.urlTask = nil
            self?.session.invalidateAndCancel()
        }
    }
    
    // MARK: - Private
    
    fileprivate func clear() {
        urlTask = nil
        logItem = nil
    }
    
    private class func isIgnore(with url: URL) -> Bool {
        guard let ignoreDomains = ignoreDomains, !ignoreDomains.isEmpty,
            let host = url.host else {
            return false
        }
        
        return ignoreDomains.first { $0.range(of: host) != nil } != nil
    }

    
}

extension NetworkLogger: URLSessionTaskDelegate, URLSessionDataDelegate {

    // MARK: - NSURLSessionDataDelegate
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        logItem?.didReceive(response: response)
        completionHandler(.allow)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        logItem?.didReceive(data: data)
        client?.urlProtocol(self, didLoad: data)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        logItem?.didCompleteWithError(error)
        
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }

        serialQueue.sync { [weak self] in
            self?.clear()
        }
        
        session.finishTasksAndInvalidate()
    }
    
}


extension NetworkLogger {
    
    public enum LogType {
        case request
        case response
    }
    
    private enum Keys {
        static let request = "GliderNetworkLogger.request"
    }

}
