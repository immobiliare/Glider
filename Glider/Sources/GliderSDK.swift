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
    public static let version = "0.9.3"

    /// Identifier of the package
    public static let identifier = "com.glider-logger"
    
    public var scope: Scope = Scope()
    
    /// Defines how contexts relevant to an event dispatch are captured.
    public var contextsCaptureOptions: ContextsCaptureOptions = .none
    
    /// Defines the frequency of refresh for captured contexts data.
    public var contextsCaptureFrequency: ContextCaptureFrequency = .default
    
    // MARK: - Initialization
    
    private init() {
        
    }
    
}

// MARK: - Glider Error

public struct GliderError: Error, LocalizedError {
    
    // MARK: - Public Properties
    
    /// Message of the error.
    public let message: String
    
    public var errorDescription: String? {
        message
    }
    
    // MARK: - Initialixation
    
    /// Initialize a new error with message.
    ///
    /// - Parameter message: message to hold.
    public init(message: String) {
        self.message = message
    }
    
}
