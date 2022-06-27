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
import NIO
import NIOConcurrencyHelpers
import Logging
import AsyncHTTPClient

public protocol GliderELKTransportDelegate: AnyObject {
    
    /// Sent when an event cannot be dispatched due to an error.
    ///
    /// - Parameters:
    ///   - transport: transport.
    ///   - event: event target.
    ///   - error: error occurred.
    func elkTransport(_ transport: GliderELKTransport, didFailSendingEvent event: Event, error: Error)
    
}
