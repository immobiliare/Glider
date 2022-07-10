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

internal extension URLSession {
    
    /// Swizzle URLSession to intercept network request.
    ///
    /// - Parameters:
    ///   - configuration: configuration.
    ///   - delegate: delegate.
    ///   - delegateQueue: delegate queue.
    /// - Returns: `URLSession`
    @objc class func custom_init(configuration: URLSessionConfiguration, delegate: URLSessionDelegate?, delegateQueue: OperationQueue?) -> URLSession {
        self.custom_init(configuration: configuration, delegate: NetworkLogger.current, delegateQueue: delegateQueue)
    }
    
}
