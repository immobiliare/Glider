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

/// This struct represent the logged user of the SDK. It will be sent along
/// each event to the specified transport layers.
public struct User {
    
    // MARK: - Public Properties
    
    /// Id of the user.
    public var userId: String
    
    /// Email of the user.
    public var email: String?
    
    /// Username.
    public var username: String?
    
    /// IP Address.
    public var ipAddress: String?
    
    /// Additional data.
    public var data: [String: Any]?
    
    // MARK: - Initialization
    
    /// Initialize a new user with the id.
    ///
    /// - Parameter userId: id of the user.
    public init(userId: String) {
        self.userId = userId
    }
    
}
