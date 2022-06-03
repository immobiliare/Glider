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

#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

/// Tags are arbitrary data can be indexed.
public typealias Tags = [String: String]

// MARK: - SerializableObject

/// An object conforms to this protocol is able to send additional data along with
/// the events is referring to.
/// Glider provides the conformance for the most common object types.
public protocol SerializableObject {
    
    /// A list of metadata properties you can attach to logged object in order to
    /// better describe it.
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

// MARK: - SerializableObject for Encodable objects

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
