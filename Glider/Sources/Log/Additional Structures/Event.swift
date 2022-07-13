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

public struct Event: Codable, Equatable {
    
    /// Identify the kind of the event.
    /// - `log`: a standard log event.
    /// - `network`: a network log event.
    public enum Kind {
        case log
        case networkLog
    }

    // MARK: - Public Properties
    
    /// Identifier of the event.
    /// It will be set automatically on init.
    public private(set) var id: String
    
    /// Message to record.
    public var message: Message
    
    /// The type of the event passed.
    public private(set) var kind: Kind = .log
    
    /// Object to serialize.
    public var object: SerializableObject?
    
    /// Sets the fingerprint in the scope.
    /// A fingerprint is a way to uniquely identify an error, and all events have one.
    /// Events with the same fingerprint may be grouped together into an issue depending
    /// on the transport service used.
    /// (For example Sentry group them in a single issue).
    public var fingerprint: String?
    
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
        scope.extra.merge(with: extra)
    }
    
    /// You can override global SDK serialization strategies here.
    /// If not specified the global value is used instead.
    public var serializationStrategies: SerializationStrategies?
    
    /// Date when the event has occurred.
    public let timestamp = Date()
    
    /// Full label of the log.
    ///
    /// NOTE:
    /// It's composed by the subsystem and category
    /// separated by a comma trimming whitespaces and newlines.
    public var label: String? {
        let composed = [subsystem, category]
            .compactMap({
                $0?.wipeCharacters(characters: "\n\r ")
            })
            .filter({
                $0.isEmpty == false
            })
        
        guard composed.isEmpty == false else {
            return nil
        }
        
        return composed.joined(separator: ":")
    }
    
    /// Associated subsystem.
    public internal(set) var subsystem: String? = nil
    
    /// Associated category.
    public internal(set) var category: String? = nil
    
    /// scope assigned to the event.
    public internal(set) var scope: Scope
    
    /// Event severity level.
    public internal(set) var level: Level = .debug
    
    // MARK: - Internal Properties
    
    /// Hold the serialized data of the object's associated.
    internal private(set) var serializedObjectData: Data?
    internal private(set) var serializedObjectMetadata: Metadata?
    internal private(set) var isSerialized = false
    
    // MARK: - Initialization
    
    /// Initialize a new event.
    ///
    /// - Parameters:
    ///   - message: message of the event.
    ///   - object: object to serialize when sending the event.
    ///   - extra: additional informations that will be sent with the event.
    ///   - tags: additional indexable informations.
    ///   - scope: scope associated with the event; if not set the global scope is used.
    public init(message: Message, object: SerializableObject? = nil,
                extra: Metadata? = nil,
                tags: Tags? = nil,
                scope: Scope = GliderSDK.shared.scope) {
        
        self.id = UUID().uuidString
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
        self.init(message: "", object: nil, extra: nil, tags: nil)
    }
    
    // MARK: - Internal Functions
    
    /// This function perform serialization of the associated event's object.
    ///
    /// - Parameter manager: manager.
    internal mutating func serializeObjectIfNeeded(withTransportManager manager: TransportManager) {
        guard isSerialized == false else {
            return // value is cached
        }

        let strategy = serializationStrategies ?? manager.serializedStrategies

        guard let object = object,
              let data = object.serialize(with: strategy) else {
            return // object is not set
        }

        self.serializedObjectMetadata = object.serializeMetadata()
        self.serializedObjectData = data
        isSerialized = true
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, message, timestamp, fingerprint, level,
             tags, extra, subsystem, category,
             scope,
             serializationStrategies,
             serializedObjectData, serializedObjectMetadata, isSerialized
    }
    
    public static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }

}
