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

public final class NetworkLogItem {
    
    // MARK: - Public Properties
    
    public private(set) var urlRequest: URLRequest
    public private(set) var urlResponse: URLResponse?
    public private(set) var startDate: Date
    public private(set) var duration: TimeInterval?
    public private(set) var data: Data?
    public private(set) var error: Error?
    
    // MARK: - Initialization
    
    internal init?(request: URLRequest) {
        guard request.url != nil else {
            return nil
        }
        
        self.urlRequest = request
        startDate = Date()
    }
    
    func didReceive(response: URLResponse) {
        self.urlResponse = response
        data = Data()
    }
    
    func didReceive(data: Data) {
        self.data?.append(data)
    }
    
    func didCompleteWithError(_ error: Error?) {
        self.error = error
        duration = fabs(startDate.timeIntervalSinceNow)
    }
    
    
}
