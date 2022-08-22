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

/// The `JSONFormatter` formatter is used to write events data
/// by using the JSON file format.
///
/// Not all properties are expressible in JSON so, for example, `object` cannot be serialized
/// unless you set the `encodeDataAsBase64` as `true` (with a sensible increment of the final payload size).
/// Keep in mind you can fix these issue by using more efficent formats [`MessagePack`](https://msgpack.org/index.html)
/// in `MsgPackFormatter`.
public class JSONFormatter: FieldsFormatter {
    
    // MARK: - Public Properties
    
    /// JSON writing option settings.
    public var jsonOptions: JSONSerialization.WritingOptions
    
    /// Encode Data using base64.
    /// By default is set to `false`, Base64 format increment the size of payload but
    /// it's necessary because JSON does not support binary data incapsulation.
    public var encodeDataAsBase64: Bool
    
    // MARK: - Initialization
    
    /// Initialize a JSON formatter.
    ///
    /// - Parameters:
    ///   - jsonOptions: options for JSON written data.
    ///   - encodeDataAsBase64: `true` to encode object's serialized data when available, `false` by default.
    ///   - fields: fields to encode.
    public init(jsonOptions: JSONSerialization.WritingOptions = [],
                encodeDataAsBase64: Bool = false,
                fields: [FieldsFormatter.Field]) {
        
        self.jsonOptions = jsonOptions
        self.encodeDataAsBase64 = encodeDataAsBase64
        super.init(fields: fields)
    }
    
    /// Use the default JSON formatter message.
    /// (`useIcon` and `severityIcon` are ignored).
    ///
    /// - Returns: `JSONFormatter`
    public override class func standard(useSubsystemIcon: Bool = false, severityIcon: Bool = true) -> JSONFormatter {
        JSONFormatter(jsonOptions: [],
                      encodeDataAsBase64: true,
                      fields: [
            .timestamp(style: .iso8601),
            .level(style: .numeric),
            .message(),
            .extra(keys: nil),
            .tags(keys: nil),
            .object(),
            .objectMetadata()
        ])
    }
    
    @available(*, unavailable)
    public override init(fields: [FieldsFormatter.Field]) {
        fatalError("Use init(options:) for JSONFormatter")
    }
    
    // MARK: - Public Functions
    
    public override func format(event: Event) -> SerializableData? {
        let jsonDictionary = keyValuesForEvent(event: event)
        return try? JSONSerialization.data(withJSONObject: jsonDictionary, options: jsonOptions).asString()
    }
    
    open func keyValuesForEvent(event: Event) -> [String: Any?] {
        var dictionary = [String: Any?]()
        
        for field in fields {
            if case .object = field.field, let data = event.serializedObjectData {
                // Only objects encoded as JSON data (basically any Codable) can be
                // expressed inside a JSON node. Raw
                if let isCodable = event.serializedObjectMetadata?["codable"] as? Bool, isCodable == true,
                   let encodedObject = String(data: data, encoding: .utf8) {
                    dictionary["object"] = encodedObject
                } else if encodeDataAsBase64 {
                    // Each Base64 digit represents exactly 6 bits of data.
                    // So, three 8-bits bytes of the input string/binary file (3×8 bits = 24 bits)
                    // can be represented by four 6-bit Base64 digits (4×6 = 24 bits).
                    //
                    // This means that the Base64 version of a string or file will
                    // be at least 133% the size of its source (a ~33% increase)
                    dictionary["object"] = data.base64EncodedString()
                }
            } else {
                guard
                    let label = field.label ?? field.field.defaultLabel,
                    let value = event.valueForFormatterField(field) else {
                        continue
                    }
                
                dictionary[label] = value
            }
        }
        
        return dictionary
    }
    
}
