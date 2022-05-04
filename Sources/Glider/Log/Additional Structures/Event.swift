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
    
    /// Identifier of the event.
    /// It will be set automatically on init.
    public let id: String = UUID().uuidString
    
    /// Message to record.
    public let message: String
    
    /// Object to serialize.
    public var object: SerializableObject?
    
    /// Date when the event has occurred.
    public let timestamp = Date()
    
    /// Associated subsystem.
    public internal(set) var subsystem: LogUUID? = nil
    
    /// Associated category.
    public internal(set) var category: LogUUID? = nil
    
    /// Arbitrary additional information that will be sent with the event.
    public var extra: Metadata?
    
    /// scope assigned to the event.
    public internal(set) var scope: Scope
    
    /// Event severity level.
    public internal(set) var level: Level = .debug
    
    // MARK: - Internal Properties
    
    /// Hold the serialized data of the object's associated.
    private var serializedObject: (metadata: Metadata?, data: Data)?
    
    // MARK: - Initialization
    
    /// Initialize a new event.
    ///
    /// - Parameters:
    ///   - message: message of the event.
    ///   - object: object to serialize when sending the event.
    ///   - extra: additional informations that will be sent with the event.
    ///   - scope: scope associated with the event; if not set the global scope is used.
    public init(_ message: String, object: SerializableObject? = nil,
                extra: Metadata? = nil,
                scope: Scope = GliderSDK.shared.scope) {
                
        self.message = message
        self.object = object
        self.scope = scope
        self.extra = extra
        
        self.scope.captureContext()
    }

}
