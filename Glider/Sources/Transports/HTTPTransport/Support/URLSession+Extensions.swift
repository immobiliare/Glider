//
//  Glider
//  Fast, Lightweight yet powerful logging system for Swift.
//
//  Created by Daniele Margutti
//  Email: hello@danielemargutti.com
//  Web: http://www.danielemargutti.com
//
//  Copyright ©2021 Daniele Margutti. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

// MARK: - Public Functions

extension URLSession {
        
    /// Execute the `URLSessionDataTask` which is part of the request, then call validate on it where we can decide if we need to retry or not.
    ///
    /// - Parameter extendedRequest: request to perform.
    /// - Parameter startImmediately: `true` to start immediately the call, default value is `true`.
    /// - Returns: URLSessionDataTask
    @discardableResult
    public func execute(_ extendedRequest: HTTPTransportRequest, startImmediately: Bool = true) -> URLSessionDataTask {
        let task = dataTask(with: extendedRequest.urlRequest) { [unowned self] data, urlResponse, error in
            let result = self.evaluateResponse(forRequest: extendedRequest, response: (data, urlResponse, error))
            self.performRetryIfNeeded(forRequest: extendedRequest, result: result)
        }

        if startImmediately {
            task.resume()
        }
        
        return task
    }
    
}

private extension URLSession {
    
    ///    Process results of `URLSessionDataTask` and converts it into `DataResult` instance
    func evaluateResponse(forRequest request: HTTPTransportRequest,
                          response: (data: Data?, urlResponse: URLResponse?, error: Error?)) -> HTTPTransportRequest.ResultData {
        
        if let urlError = response.error as? URLError {
            return .failure(HTTPTransportRequest.RequestError.network(urlError) )

        } else if let otherError = response.error {
            return .failure(HTTPTransportRequest.RequestError.internal(otherError) )
        }

        guard let httpResponse = response.urlResponse as? HTTPURLResponse else {
            if let urlResponse = response.urlResponse {
                return .failure(HTTPTransportRequest.RequestError.invalidResponse(urlResponse) )
            } else {
                return .failure(HTTPTransportRequest.RequestError.noResponse)
            }
        }

        if httpResponse.statusCode >= 400 {
            return .failure(HTTPTransportRequest.RequestError.httpError(httpResponse, response.data) )
        }

        guard let data = response.data, !data.isEmpty else {
            if request.configuration.acceptEmptyResponse {
                // Allows empty response as result of the call
                return .success(Data())
            }

            return .failure(HTTPTransportRequest.RequestError.emptyResponse(httpResponse) )
        }

        return .success(data)
    }
    
    /// Execute retry of the call if criteria are meet.
    ///
    /// - Parameters:
    ///   - request: request.
    ///   - result: Bool which indicate if the request will be re-executed.
    @discardableResult
    func performRetryIfNeeded(forRequest request: HTTPTransportRequest, result: HTTPTransportRequest.ResultData) -> Bool {
        guard let callback = request.onComplete else {
            return false
        }
        
        if case .failure(let error) = result {
            guard request.shouldRetry(forError: error as? HTTPTransportRequest.RequestError) else {
                callback(result)
                return false
            }
            
            var newRequest = request
            newRequest.currentRetry += 1
            
            if newRequest.currentRetry >= newRequest.configuration.maxRetries {
                callback(.failure(HTTPTransportRequest.RequestError.inaccessible))
                return true
            }
            
            // try again
            self.execute(newRequest)
        }
        
        callback(result)
        return false
    }
    
}
