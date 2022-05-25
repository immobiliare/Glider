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

/// The `MsgPackDataFormatter` allows to transform payload or scopes into message-pack data format.
public class MsgPackFormatter: FieldsFormatter {
    
    /// Return the default formatter for `MsgPackFormatter` with the following fields:
    /// - iso8601 timestamp
    /// - level of severity as numeric
    /// - message text
    /// - object metadata
    /// - object serialized
    ///
    /// - Returns: MsgPackFormatter
    public override class func `default`() -> MsgPackFormatter {
        MsgPackFormatter(fields: [
            .timestamp(style: .iso8601),
            .level(style: .numeric),
            .message(),
            .objectMetadata(keys: nil),
            .object(),
            .extra(keys: nil),
            .tags(keys: nil)
        ])
    }
    
    // MARK: - Overrides
    
    public override func format(event: Event) -> SerializableData? {
        let data = payloadDictionary(forEvent: event)
        return try? data.toMessagePack()
    }
    
    // MARK: - Private Functions
    
    private func payloadDictionary(forEvent event: Event) -> [String: Any?] {
        var dictionary = [String: Any?]()
        
        for field in fields {
            guard
                let key = field.label ?? field.field.defaultLabel,
                let value = event.valueForFormatterField(field) else {
                continue
            }
            
            dictionary[key] = value
        }
        
        return dictionary
    }
    
}

// MARK: - Dictionary

fileprivate extension Dictionary where Key == String, Value == Any? {
    
    /// Transform dictionary into message pack data stream.
    ///
    /// - Throws: throw an exception if conversion fails.
    /// - Returns: Data
    func toMessagePack() throws -> Data {
        var encoder = MessagePackWriter()
        try encoder.pack(self)
        return encoder.data
    }
    
}
