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

/// Delegate of the logzio service which receive events from the service.
public protocol GliderLogglyTransportDelegate: AnyObject {
    
    /// Called when a bulk of logs has been sent to the logzio service.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - records: loggable records sent.
    ///   - result: result of the operaiton.
    func logglyTransport(_ transport: GliderLogglyTransport,
                         didSendRecords records: [LoggableRecord],
                         result: Result<Data,Error>?)
    
}
