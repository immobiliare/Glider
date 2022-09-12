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
import Sentry

// MARK: - Level

extension Glider.Level {
    
    /// Return compatible `SentryLevel` from Glider's `Level`.
    /// - Returns: SentryLevel
    public var sentryLevel: SentryLevel {
        switch self {
        case .emergency: return .fatal
        case .alert: return .fatal
        case .critical: return .error
        case .error: return .error
        case .warning: return .warning
        case .notice: return .info
        case .info: return .info
        case .debug: return .debug
        case .trace: return .debug
        }
    }
    
}

// MARK: - Event

extension Glider.Event {
    
    /// Create a `Sentry.Event` instance from a Glider's `Event` object.
    /// - Returns: `Sentry.Event`
    internal func toSentryEvent(withMessage message: SerializableData?) -> Sentry.Event {
        let sentryEvent = Sentry.Event(level: level.sentryLevel)
        sentryEvent.eventId = SentryId(uuidString: id)
        sentryEvent.message = SentryMessage(formatted: message?.asString() ?? "")
        sentryEvent.timestamp = timestamp
        
        if let fingerprint = fingerprint {
            sentryEvent.fingerprint = [fingerprint]
        }
        
        sentryEvent.extra = self.extra?.values.compactMapValues({ $0 })
        sentryEvent.tags = self.tags
        
        return sentryEvent
    }
    
}

// MARK: - User

extension Glider.User {
    
    /// Transform the user into the `Sentry.User` instance.
    /// - Returns: `Sentry.User`
    internal func toSentryUser() -> Sentry.User {
        let user = Sentry.User(userId: self.userId)
        user.email = self.email
        user.username = self.username
        user.ipAddress = self.ipAddress
        user.data = self.data
        return user
    }
    
}
