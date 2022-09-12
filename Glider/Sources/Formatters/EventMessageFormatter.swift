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

/// `EventMessageFormatter` is a protocol used to format the message text of the `Event`
/// when a transport attempt to store according to its settings.
/// Not all transports may use formatter/s to store data.`
public protocol EventMessageFormatter {
    
    /// Called to create a string representation of the passed-in event.
    ///
    /// - Returns: A `String` representation of `entry`, or `nil` if the
    ///            receiver could not format the `LogEntry`.
    func format(event: Event) -> SerializableData?
    
}

/// `SerializableData` is a protocol used to create serializable representation
/// of some data, typically `extra` and `tags` values.
public protocol SerializableData {
    
    /// Return the string representation of the value.
    ///
    /// - Returns: `String?`
    func asString() -> String?
    
    /// Return the data representation of the value.
    ///
    /// - Returns: `Data?`
    func asData() -> Data?
    
}

extension Data: SerializableData {
    
    public func asData() -> Data? {
        self
    }
    
    public func asString() -> String? {
        String(data: self, encoding: .utf8)
    }
    
}

extension Bool: SerializableData {
    
    public func asData() -> Data? {
        self.asString()?.data(using: .utf8)
    }
    
    public func asString() -> String? {
        self  == true ? "1" : "0"
    }
    
}

extension Int: SerializableData {
    
    public func asData() -> Data? {
        self.asString()?.data(using: .utf8)
    }
    
    public func asString() -> String? {
        "\(self)"
    }
    
}

extension String: SerializableData {
    
    public func asString() -> String? {
        self
    }
    
    public func asData() -> Data? {
        self.data(using: .utf8)
    }
}

extension Array where Element == EventMessageFormatter {
    
    public func format(event: Event) -> SerializableData? {
        for formatter in self {
            if let formattedString = formatter.format(event: event) {
                return formattedString
            }
        }
        
        return nil
    }
    
}
