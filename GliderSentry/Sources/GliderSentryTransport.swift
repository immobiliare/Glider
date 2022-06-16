//
//  GliderSentry
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
import Sentry

open class GliderSentryTransport: Transport {
    
    // MARK: - Public Properties
    
    /// GCD queue.
    public var queue: DispatchQueue?
    
    /// Is logging enabled.
    public var isEnabled: Bool = true
    
    /// Configuration.
    public let configuration: Configuration
    
    // MARK: - Initialization
    
    /// Initialize a new Sentry transport service.
    /// - Parameter builder: builder pattern.
    public init(_ builder: ((inout Configuration) -> Void)? = nil) {
        self.configuration = Configuration(builder)
    
        if let sdkConfiguration = configuration.sdkConfiguration {
            SentrySDK.start(options: sdkConfiguration)
        }
    }
    
    // MARK: - Conformance
    
    public func record(event: Glider.Event) -> Bool {
        guard isEnabled else { return false }
        
        let message = configuration.formatters.format(event: event)
        let sentryEvent = event.toSentryEvent(withMessage: message)
        
        sentryEvent.environment = configuration.environment
        sentryEvent.logger = configuration.loggerName
        sentryEvent.user = event.scope.user?.toSentryUser()
        
        SentrySDK.capture(event: sentryEvent) {
            $0.setExtras(event.scope.extra.values.compactMapValues({ $0 }))
            $0.setTags(event.scope.tags)
        }

        return true
    }
    
}
