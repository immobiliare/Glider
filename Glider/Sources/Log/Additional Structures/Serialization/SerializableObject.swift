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

#if os(iOS) || os(tvOS)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

/// Tags are arbitrary data can be indexed.
public typealias Tags = [String: String]

// MARK: - SerializableObject

/// In order to attach additional objects to a message payload, these objects must
/// be conform to the `SerializableObject` protocol.
/// This protocol defines a list of function used to create a binary representation
/// of an object.
///
/// Glider offers automatically conformance to `SerializableObject` for any object
/// already conforms to `Codable` protocol and any other of the standard data type
/// (strings, numbers, dates and so on).
public protocol SerializableObject {
    
    /// A list of metadata properties you can attach to logged object in order to
    /// better describe it.
    ///
    /// By default the `class` and `type` properties are filled automatically for you.
    /// For `UIImage` it also includes `scale`, `width` and `height` properties.
    /// - Returns: Metadata
    func serializeMetadata() -> Metadata?
    
    /// Convert object to raw binary data representation (if any).
    ///
    /// You can customize this function in order to transform
    /// an object in a set of data you can send over the network.
    ///
    /// By default it return:
    /// - for `UIImage`: the jpg representation of the image using the `imageLoggableStrategy` settings.
    /// - for `Codable` structures: the json of the structure
    /// - `nil` otherwise (customize as you need).
    func serialize(with strategies: SerializationStrategies) -> Data?

}

// MARK: - SerializableObject for Codable

public extension SerializableObject where Self: Codable {
    
    func serialize(with strategies: SerializationStrategies) -> Data? {
        try? JSONEncoder().encode(self)
    }
    
    func serializeMetadata() -> Metadata? {
        return Metadata([
            "class": String(describing: type(of: self)),
            "codable": true
        ])
    }

}
