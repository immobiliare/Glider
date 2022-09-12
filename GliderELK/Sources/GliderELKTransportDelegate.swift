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
import Glider
import NIO
import NIOConcurrencyHelpers
import Logging
import AsyncHTTPClient

/// The delegate used to receive important notifications from a `GliderELKTransport`,
public protocol GliderELKTransportDelegate: AnyObject {
    
    /// Sent when an event cannot be dispatched due to an error.
    ///
    /// - Parameters:
    ///   - transport: transport.
    ///   - event: event target.
    ///   - error: error occurred.
    func elkTransport(_ transport: GliderELKTransport, didFailSendingEvent event: Event, error: Error)
    
}
