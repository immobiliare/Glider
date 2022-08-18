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

/// Filters are used to early discard message payloads (`Event`)
/// before sending them to the transport of a logger instance.
///
/// A filter is an object that conforms to `TransportFilter` protocol and implements the `shouldAccept()`
/// function where you can define your business logic to accept or discard any event received.
/// Logger's filters (defined by the `filters` property) are executed in order.
/// Once a filter discards a message, the chain is interrupted, and the logger immediately ignores the message.
///
/// This is an example of a filter to accept only events with a special value of `username` key in `extra` field.
///
/// ```swift
/// struct MyFilter: TransportFilter {
///
///   func shouldAccept(_ event: Event) -> Bool {
///      event.extra?.values["username"] as? String == "vipuser"
///   }
/// }
///
/// let log = Log {
///     $0.filters = [MyFilter()]
///     // other configuration...
/// }
/// ```
///
public protocol TransportFilter {
        
    /// Called to determine whether the given `Event` should be recorded or ignored.
    ///
    /// - Parameter event: The payload to be evaluated by the filter.
    func shouldAccept(_ event: Event) -> Bool
    
}
