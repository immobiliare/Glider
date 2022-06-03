//
//  File.swift
//  
//
//  Created by Daniele Margutti on 01/06/22.
//

import Foundation

public struct Metadata: Codable, ExpressibleByDictionaryLiteral {
    
    // MARK: - Public Properties
    
    public private(set) var values = [String: SerializableData?]()
    
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
        let encodedData = try JSONSerialization.data(withJSONObject: encodableExtraDict, options: .sortedKeys)
        try container.encodeIfPresent(encodedData, forKey: .values)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let data = try container.decodeIfPresent(Data.self, forKey: .values),
           let decodedExtraData: [String: SerializableData] = try JSONSerialization.jsonObject(with: data) as? [String: Data] {
            self.values = decodedExtraData
        } else {
            self.values = [:]
        }
    }
    
    
}
