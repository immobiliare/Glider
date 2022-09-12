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

/// Represent a single HTTP request made by the `HTTPTransport`.
/// It encapsulates a valid `URLRequest` along with extra configuration
/// attributes like retry mechanism and error handling.
public struct HTTPTransportRequest {
    
    /// Typealiases.
    public typealias ResultData = Result<Data, Error>
    public typealias Callback = (ResultData) -> Void
    
    // MARK: - Public Properties
    
    /// URLRequest to execute.
    public let urlRequest: URLRequest
    
    /// Configuration
    public let configuration: Configuration
    
    // MARK: - Internal Functions
    
    /// Callback called to receive data.
    internal var onComplete: Callback?
    
    /// Current retry attempt.
    internal var currentRetry = 0
    
    // MARK: - Initialization
    
    /// Initialize a new `HTTPTransportRequest` with an url request.
    /// - Parameters:
    ///   - urlRequest: url request to execute.
    ///   - builder: builder function to customize the call.
    public init(urlRequest: URLRequest, _ builder: ((inout Configuration) -> Void)? = nil) {
        self.configuration = Configuration(builder)
        self.urlRequest = urlRequest
    }
    
    // MARK: - Open Functions
    
    internal func shouldRetry(forError error: RequestError?) -> Bool {
        guard let error = error else {
            return false
        }
        
        return configuration.shouldRetryRequestHandler?(error) ?? false
    }
    
}

// MARK: - Configuration

extension HTTPTransportRequest {
    
    public struct Configuration {
        
        /// Number of retries. By default is 0 which means no retry is made.
        public var maxRetries: Int = 0
        
        /// Allows empty responses for `HTTPTransportRequest` requests.
        /// By default is set to `true` which mean an empty response is not considered an error.
        public var acceptEmptyResponse = true
        
        /// This handler allows you to define the rule to control the optional retry for failures.
        /// By default all networking related errors catch an automatic retry:
        /// `timedOut`,`cannotFindHost`, `cannotConnectToHost`, `networkConnectionLost`, `dnsLookupFailed`.
        public var shouldRetryRequestHandler: ((RequestError) -> Bool)?
            
        public init(_ builder: ((inout Configuration) -> Void)?) {
            self.shouldRetryRequestHandler = { error in
                let retriableErrorTypes: [URLError.Code] = [
                    .timedOut,
                    .cannotFindHost,
                    .cannotConnectToHost,
                    .networkConnectionLost,
                    .dnsLookupFailed
                ]
                
                switch error {
                case .network(let error):
                    return retriableErrorTypes.contains(error.code)
                default:
                    return false
                }
            }
            
            builder?(&self)
        }
        
    }
    
}

// MARK: - HTTPTransportRequestError

extension HTTPTransportRequest {
    
    /// Declaration of the errors which are throw/return from URLSession.
    /// - `inaccessible`: Happend when network connection is so bad which after `maxRetries` the request did not succeded.
    /// - `network`: Network specific error you can handle.
    /// - `internal`: Internal error for any error which is not an `URLError`.
    /// - `noResponse`: When no `URLResponse` is returned and no error is returned too.
    /// - `invalidResponse`: When `URLResponse` is not `HTTPURLResponse`.
    /// - `emptyResponse`: Status code is in `200...299` range, but response body is empty.
    ///                   This can be both valid and invalid, depending on HTTP method and/or specific behavior of the service being called.
    /// - `httpError`: Status code is `400` or higher thus return the entire `HTTPURLResponse` and `Data` so caller can figure out what happened.
    public enum RequestError: Error {
        case inaccessible
        case network(URLError)
        case `internal`(Swift.Error)
        case noResponse
        case invalidResponse(URLResponse)
        case emptyResponse(HTTPURLResponse)
        case httpError(HTTPURLResponse, Data?)
    }
    
}
