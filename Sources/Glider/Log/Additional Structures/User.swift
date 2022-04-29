//
//  File.swift
//  
//
//  Created by Daniele Margutti on 26/04/22.
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
