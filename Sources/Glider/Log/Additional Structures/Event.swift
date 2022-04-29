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

public struct Event {

    // MARK: - Public Properties
    
    /// Message to record.
    public let message: String
    
    /// scope assigned to the event.
    public let scope: Scope
    
    /// Event severity level.
    public var level: Level = .debug
    
    // MARK: - Initialization
    
    public init(_ message: String, scope: Scope = GliderSDK.shared.scope) {
        self.message = message
        self.scope = scope
    }

}
