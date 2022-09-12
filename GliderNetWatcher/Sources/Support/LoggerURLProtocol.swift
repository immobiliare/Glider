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

/// `LoggerURLProtocol` is a custom implementation
/// of `URLProtocol` used to intercept and record each request.
/// You should never use this class directly, it's automatically managed by `NetWatcher`.
internal class LoggerURLProtocol: URLProtocol {
    private static let RequestHandledKey = "URLProtocolRequestHandled"

    // MARK: - Internal Properties
    
    internal static var ignoredHosts = [String]()
    
    // MARK: - Fileprivate Properties
    
    /// URL Session.
    fileprivate var session: URLSession?
    
    /// URL Session Task.
    fileprivate var sessionTask: URLSessionDataTask?
    
    /// Request payload.
    fileprivate var currentRequest: NetworkEvent?
    
    // MARK: - Private Properties
    
    /// Payload.
    private let serialQueue = DispatchQueue(label: "com.glider.networklogger.serialqueue")
    
    // MARK: - URLProtocol
    
    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        super.init(request: request, cachedResponse: cachedResponse, client: client)
        
        if session == nil {
            session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        }
    }
    
    deinit {
        session = nil
        sessionTask = nil
        currentRequest = nil
    }
    
    override public class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url, let scheme = url.scheme else {
            didIgnoreRequest(request)
            return false
        }
        
        if let shouldRecord = NetWatcher.shared.delegate?.netWatcher(NetWatcher.shared, shouldRecordRequest: request),
           shouldRecord == false {
            didIgnoreRequest(request)
            return false
        }

        guard !isURLIgnored(url) else {
            didIgnoreRequest(request)
            return false
        }
        
        return ["http", "https"].contains(scheme) && self.property(forKey: Self.RequestHandledKey, in: request)  == nil
    }
    
    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override public func startLoading() {
        let newRequest = ((request as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
        Self.setProperty(true, forKey: Self.RequestHandledKey, in: newRequest)
        
        sessionTask = session?.dataTask(with: newRequest as URLRequest)
        sessionTask?.resume()
        
        currentRequest = NetworkEvent(request: newRequest, inSession: session)
    }
    
    override public func stopLoading() {
        serialQueue.sync { [weak self] in
            self?.sessionTask?.cancel()
            self?.sessionTask = nil
            self?.session?.invalidateAndCancel()
            self?.session = nil
        }
    }
    
    // MARK: - Private Functions
        
    private class func isURLIgnored(_ url: URL) -> Bool {
        guard !ignoredHosts.isEmpty,
              let host = url.host else {
            return false
        }
        
        return ignoredHosts.first { $0.range(of: host) != nil } != nil
    }
    
    private static func didIgnoreRequest(_ request: URLRequest) {
        DispatchQueue.main.async {
            NetWatcher.shared.delegate?.netWatcher(NetWatcher.shared, didIgnoreRequest: request)
        }
    }

}

// MARK: - URLSessionDataDelegate

extension LoggerURLProtocol: URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                           didReceive data: Data) {
        currentRequest?.didReceive(data: data)
        client?.urlProtocol(self, didLoad: data)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                           didReceive response: URLResponse,
                           completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        currentRequest?.didReceive(response: response)

        let policy = URLCache.StoragePolicy(rawValue: request.cachePolicy.rawValue) ?? .notAllowed
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: policy)
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask,
                           didCompleteWithError error: Error?) {
        guard let error = error else {
            NetWatcher.shared.record(currentRequest)
            didCaptureNewEvent()
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        currentRequest?.didCompleteWithError(error)
        NetWatcher.shared.record(currentRequest)
        didCaptureNewEvent()
        client?.urlProtocol(self, didFailWithError: error)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask,
                           willPerformHTTPRedirection response: HTTPURLResponse,
                           newRequest request: URLRequest,
                           completionHandler: @escaping (URLRequest?) -> Void) {
        client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
        completionHandler(request)
    }
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        guard let error = error else {
            return
        }
        
        currentRequest?.didCompleteWithError(error)
        didCaptureNewEvent()
        client?.urlProtocol(self, didFailWithError: error)
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let wrappedChallenge = URLAuthenticationChallenge(authenticationChallenge: challenge, sender: CustomAuthenticationChallengeSender(handler: completionHandler))
        client?.urlProtocol(self, didReceive: wrappedChallenge)
    }
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        client?.urlProtocolDidFinishLoading(self)
    }
    
    // MARK: - Private Functions
    
    private func didCaptureNewEvent() {
        guard let networkEvent = currentRequest else {
            return
        }
        
        DispatchQueue.main.async {
            NetWatcher.shared.delegate?.netWatcher(NetWatcher.shared, didCaptureEvent: networkEvent)
        }
    }
    
}
