//
//  Glider
//  Fast, Lightweight yet powerful logging system for Swift.
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Authors:
//   - Daniele Margutti <hello@danielemargutti.com>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

/// A metadata is a container of key,value entries. It's basically a dictionary
/// where you can store useful informations you can bring along with your event.
///
/// You can set a global metadata entries inside the `GliderSDK.shared.scope` variable
/// or per single event using the `metadata` property.
///
/// Each value of metadata must be conform to `SerializableData` in order to be
/// serialized and stored. All the default Swift data types are conform to this
/// protocol, but you can also provide an implementation for your custom objects.
///
public struct Metadata: Codable, ExpressibleByDictionaryLiteral {
    
    // MARK: - Public Properties
    
    /// Dictionary with values
    public private(set) var values = [String: SerializableData?]()
    
    /// A list of all stored keys
    public var keys: [String] {
        Array(values.keys)
    }
    
    // MARK: - Initialization
    
    /// Initialize a new metadata dictionary with a list of key values.
    ///
    /// - Parameter values: key values dictionary.
    public init(_ values: [String: SerializableData?] = [:]) {
        self.values = values
    }
    
    public init(dictionaryLiteral elements: (String, SerializableData?)...) {
        for element in elements {
            values[element.0] = element.1
        }
    }
    
    // MARK: - Public Functions
    
    public subscript(key: String) -> SerializableData? {
        get {
            values[key] ?? nil
        }
        set {
            values[key] = newValue
        }
    }
    
    /// Produce a JSON representation of the metadata object.
    ///
    /// - Returns: `String`
    public func asString() -> String? {
        var json: Data?
        if #available(iOS 11.0, *) {
            json = try? JSONSerialization.data(withJSONObject: self, options: .sortedKeys)
        } else {
            json = try? JSONSerialization.data(withJSONObject: self)
        }
        return json?.asString()
    }
    
    // MARK: - Internal Functions
    
    func merge(with otherMetadata: Metadata?) -> Metadata {
        guard let otherMetadata = otherMetadata else {
            return self
        }
        
        let result = values.merging(otherMetadata.values, uniquingKeysWith: { (_, new) in
            new
        })
        return Metadata(result)
    }
    
    internal func filteredByKeys(_ keys: [String]?) -> [String: SerializableData?] {
        values.filteredByKeys(keys)
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case values
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let encodableExtraDict: [String: Data?] = values.mapValues({ $0?.asData() })

        if #available(iOS 11.0, *) {
            let rawData = try NSKeyedArchiver.archivedData(withRootObject: encodableExtraDict, requiringSecureCoding: false)
            try container.encode(rawData, forKey: .values)
        } else {
            let rawData = NSKeyedArchiver.archivedData(withRootObject: encodableExtraDict)
            try container.encode(rawData, forKey: .values)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let rawValues = try container.decode(Data.self, forKey: .values)
        self.values = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(rawValues) as? [String: Data?] ?? [:]
    }
    
}
