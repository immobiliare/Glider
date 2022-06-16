//
//  File.swift
//  
//
//  Created by Daniele Margutti on 01/06/22.
//

import Foundation

public struct Metadata: Codable, ExpressibleByDictionaryLiteral {
    
    // MARK: - Public Properties
    
    /// Dictionary.
    public private(set) var values = [String: SerializableData?]()
    
    /// Keys stored.
    public var keys: [String] {
        Array(values.keys)
    }
    
    // MARK: - Initialization
    
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
    
    public func asString() -> String? {
        let json = try? JSONSerialization.data(withJSONObject: self, options: .sortedKeys)
        return json?.asString()
    }
    
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

        let rawData = try NSKeyedArchiver.archivedData(withRootObject: encodableExtraDict, requiringSecureCoding: false)
        try container.encode(rawData, forKey: .values)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let rawValues = try container.decode(Data.self, forKey: .values)
        self.values = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(rawValues) as? [String: Data?] ?? [:]
    }
    
    
}
