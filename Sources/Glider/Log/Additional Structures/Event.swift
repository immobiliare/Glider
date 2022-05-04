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
    ///   - tags: additional indexable informations.
    ///   - scope: scope associated with the event; if not set the global scope is used.
    public init(_ message: String, object: SerializableObject? = nil,
                extra: Metadata? = nil,
                tags: Tags? = nil,
                scope: Scope = GliderSDK.shared.scope) {
                
        self.message = message
        self.object = object
        self.scope = scope
        self.scope.extra = Dictionary.merge(baseDictionary: scope.extra, additionalData: extra)
        self.scope.tags = Dictionary.merge(baseDictionary: scope.tags, additionalData: tags)
        
        // Capture the current context if set.
        self.scope.captureContext()
    }

}

extension Dictionary {
    
    internal static func merge(baseDictionary: [Key: Value], additionalData:  [Key: Value]?) ->  [Key: Value] {
        guard let additionalData = additionalData else {
            return baseDictionary
        }
        
        let result = baseDictionary.merging(additionalData, uniquingKeysWith: { (_, new) in
            new
        })
        return result
    }
    
}
