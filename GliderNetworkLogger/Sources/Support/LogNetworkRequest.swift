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

/// Identify a single intercepted request+response from network; this
/// object is generated automatically from the `NetworkLogger` class
/// when activated.
public struct LogNetworkRequest {
    
    // MARK: - Public Properties
    
    /// Request origin.
    public private(set) var urlRequest: URLRequest
    
    /// Parent `URLSession` instance.
    public private(set) var urlSession: URLSession?
    
    /// Response received.
    public private(set) var urlResponse: URLResponse?
    
    /// Status code received.
    public var statusCode: Int? {
        httpResponse?.statusCode
    }
    
    /// HTTP Response received.
    public var httpResponse: HTTPURLResponse? {
        urlResponse as? HTTPURLResponse
    }
    
    /// Request start date.
    public private(set) var startDate: Date
    
    /// Duration of the request+reponse.
    public private(set) var duration: TimeInterval?
    
    /// Received data.
    public private(set) var data: Data?
    
    /// Error occurred, if any.
    public private(set) var error: Error?
    
    // MARK: - Initialization
    
    internal init?(request: NSMutableURLRequest, inSession session: URLSession?) {
        guard request.url != nil else {
            return nil
        }
        
        self.urlRequest = request as URLRequest
        self.urlSession = session
        startDate = Date()
    }
    
    // MARK: - Internal Function
    
    internal mutating func didReceive(data: Data) {
        if self.data == nil {
            self.data = data
        } else {
            self.data?.append(data)
        }
    }
    
    internal mutating func didReceive(response: URLResponse) {
        self.urlResponse = response
        self.data = Data()
    }
    
    internal mutating func didCompleteWithError(_ error: Error?) {
        self.error = error
        duration = fabs(startDate.timeIntervalSinceNow)
    }
    
    
}
