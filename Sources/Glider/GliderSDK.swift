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
    public static let version = "1.0.0"
    
    public var scope: Scope = Scope()
    
    // MARK: - Initialization
    
    private init() {
        
    }
    
}
