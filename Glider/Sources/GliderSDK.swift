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

public class GliderSDK {
    
    // MARK: - Public Properties
    
    /// Shared instance of the Glider SDK
    public static let shared = GliderSDK()
    
    /// SDK Current Version.
    public static let version = "0.9.19"

    /// Identifier of the package
    public static let identifier = "com.glider-logger"
    
    /// Locale used when formatting strings for log.
    /// By default is set to `current`.
    public var locale: Locale = .current
    
    /// Set to `true` to disable the privacy support in log message
    /// interpolation (ie. sending `"\(user.email, privacy: .private)"`.
    /// By default is set to `true` on `#DEBUG` builds and `false` otherwise.
    ///
    /// You can however override this value at startup in order to test
    /// how redaction works while debugging.
    public var disablePrivacyRedaction = false
    
    /// Current scope.
    public var scope: Scope = Scope()
    
    /// Defines how contexts relevant to an event dispatch are captured.
    public var contextsCaptureOptions: ContextsCaptureOptions = .none
    
    /// Defines the frequency of refresh for captured contexts data.
    public var contextsCaptureFrequency: ContextCaptureFrequency = .default
    
    // MARK: - Initialization
    
    private init() {
       reset()
    }
    
    // MARK: - Public Function
    
    /// Reset the state of settings including the generation of a new scope.
    public func reset() {
        #if DEBUG
        self.disablePrivacyRedaction = true
        #else
        self.disablePrivacyRedaction = false
        #endif
        
        self.scope = Scope()
        self.contextsCaptureOptions = .none
        self.contextsCaptureFrequency = .default
        self.locale = .current
    }
}

// MARK: - Glider Error

public struct GliderError: Error, LocalizedError {
    
    // MARK: - Public Properties
    
    /// Message of the error.
    public let message: String
    
    /// Additional info dictionary.
    public var info: [String: Any]
    
    /// Description of the error.
    public var errorDescription: String? {
        message
    }
    
    // MARK: - Initialixation
    
    /// Initialize a new error with message.
    ///
    /// - Parameter message: message to hold.
    public init(message: String, info: [String: Any] = [:]) {
        self.message = message
        self.info = info
    }
    
}
