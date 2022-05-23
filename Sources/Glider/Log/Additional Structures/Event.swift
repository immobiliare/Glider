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
    public var message: String
    
    /// Object to serialize.
    public var object: SerializableObject?
    
    /// Tags are key/value string pairs.
    /// Some transports may index and make them searchable (like sentry).
    /// Values can be overriden by the event's `tags` informations.
    public var tags: Tags?
    
    /// Arbitrary additional information that will be sent with the event.
    /// Values can be overriden by the event's `extra` informations.
    public var extra: Metadata?
    
    /// Return cumulative list of all tags where the base is scope's tags
    /// merged with event's specific tags
    public var allTags: Tags? {
        Dictionary.merge(baseDictionary: scope.tags, additionalData: tags)
    }
    
    /// Return cumulative list of all metadata where the base is scope's metadata
    /// merged with event's specific metadata.
    public var allExtra: Metadata? {
        Dictionary.merge(baseDictionary: scope.extra, additionalData: extra)
    }
    
    /// You can override global SDK serialization strategies here.
    /// If not specified the global value is used instead.
    public var serializationStrategies: SerializationStrategies?
    
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
    internal private(set) var serializedObject: (metadata: Metadata?, data: Data)?
    
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
        self.extra = extra
        self.tags = tags
        
        // Capture the current context if set.
        self.scope.captureContext()
    }
    
    /// Initialize a new empty event.
    internal init() {
        self.init("", object: nil, extra: nil, tags: nil)
    }
    
    // MARK: - Internal Functions
    
    /// This function perform serialization of the associated event's object.
    ///
    /// - Parameter manager: manager.
    internal mutating func serializeObjectIfNeeded(withTransportManager manager: TransportManager) {
        guard serializedObject == nil else {
            return // value is cached
        }

        let strategy = serializationStrategies ?? manager.serializedStrategies

        guard let object = object,
              let data = object.serialize(with: strategy) else {
            return // object is not set
        }

        self.serializedObject = (object.serializeMetadata(), data)
    }
    
}

// MARK: - Dictionary Extensions

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
