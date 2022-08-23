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

/// The `GliderSentryTransport` is used to forward the messages
///  coming from `Glider` logging system to the [Sentry](https://github.com/getsentry/sentry-cocoa) official SDK.
open class GliderSentryTransport: Transport {
    
    // MARK: - Public Properties
    
    /// The `DispatchQueue` to use for the recorder.
    public var queue: DispatchQueue
    
    /// Is logging enabled.
    public var isEnabled: Bool = true
    
    /// Configuration to create `GliderSentryTransport`.
    public let configuration: Configuration
    
    /// Minumum accepted level for this transport.
    /// `nil` means every passing message level is accepted.
    public var minimumAcceptedLevel: Level?
    
    // MARK: - Private Properties
    
    /// Setup the environment of the log.
    /// 
    /// It will set by SDK global but you can override at level scope by
    /// setting the event's `scope.environment` value.
    public static var environment: String? {
        didSet {
            SentrySDK.configureScope {
                $0.setEnvironment(environment)
            }
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize a new configuration.
    ///
    /// - Parameter configuration: configuration.
    public init(configuration: Configuration) {
        self.configuration = configuration
        self.isEnabled = configuration.isEnabled
        self.queue = configuration.queue
        self.minimumAcceptedLevel = configuration.minimumAcceptedLevel
        
        if let sdkConfiguration = configuration.sdkConfiguration {
            SentrySDK.start(options: sdkConfiguration)
        }
    }
    
    /// Initialize a new Sentry transport service.
    ///
    /// - Parameter builder: builder pattern.
    public convenience init(_ builder: ((inout Configuration) -> Void)? = nil) {
        self.init(configuration: Configuration(builder))
    }
    
    // MARK: - Public Functions
    
    // MARK: - Conformance
    
    public func record(event: Glider.Event) -> Bool {        
        let message = configuration.formatters.format(event: event)
        let sentryEvent = event.toSentryEvent(withMessage: message)
        
        sentryEvent.environment = configuration.environment ?? Self.environment
        sentryEvent.logger = configuration.loggerName
        sentryEvent.user = event.scope.user?.toSentryUser()
        
        SentrySDK.capture(event: sentryEvent) {
            $0.setExtras(event.scope.extra.values.compactMapValues({ $0 }))
            $0.setTags(event.scope.tags)
        }

        return true
    }
    
}
