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

/// The `MsgPackDataFormatter` allows to store `Event` data using the [`MessagePack`](https://msgpack.org/index.html) file
/// format which produce a compact (and faster to read) representation of the data compared to other formats like JSON.
public class MsgPackFormatter: FieldsFormatter {
    
    /// Return the default formatter for `MsgPackFormatter` with the following fields:
    ///
    /// - ISO8601 timestamp
    /// - level of severity as numeric
    /// - message text
    /// - object metadata
    /// - object serialized
    ///
    /// (`useIcon` and `severityIcon` are ignored).
    ///
    /// - Returns: `MsgPackFormatter`
    public override class func standard(useSubsystemIcon: Bool = false, severityIcon: Bool = true) -> MsgPackFormatter {
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
    
    /// Create a serializable payload of the event according to the specified fields.
    ///
    /// - Parameter event: target event.
    /// - Returns: `[String: Any?]`
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
