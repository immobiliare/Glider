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

/// Represent the message of a log.
/// We have used a custom object instead of plain `String` to supports custom object interpolations
/// via `StringInterpolationProtocol` (we have choosed to not implement interpolation methods directly
/// on `String` object in order to avoid confusion).
/// When coded the message itself it's just a literal and loose the composed values.
///

/// Represent the message content of an `Event` payload.
/// This object cannot be a plain `String` in order to support complex string interpolation.
/// This is useful when you need to compose a message which includes some variables and you need to take
/// care of privacy or formatting concerns.
///
/// For example you can use the Glider's privacy support to compose a message like this:
///
/// ```swift
///  log.info?.write({
///     $0.message = "Hello \(username, privacy: .public), your email is \(email, privacy: .partiallyHide), token \(token, privacy: .private))"
///  })
/// ```
///
/// The following code compose a message string where:
/// - the `username` variable is always visible
/// - the `email` variable is partially visible on production logs
/// - the `token` variable is redacted on production logs
///
/// This is useful when you need to guarantee a certain level of privacy of the data.  
/// Variables are always visible while debugging.
public struct Message: ExpressibleByStringInterpolation, ExpressibleByStringLiteral, CustomStringConvertible, Codable, SerializableData {
    
    // MARK: - Public Properties
    
    /// Plain text content of the message.
    public private(set) var content: String
    
    // MARK: - Initializzation
    
    /// Initialize with a new literal value.
    ///
    /// - Parameter value: value.
    public init(stringLiteral value: String) {
        self.content = LogInterpolation(literal: value).content()
    }
    
    /// Initialize with a string interpolated message.
    ///
    /// - Parameter stringInterpolation: string interpolated message
    public init(stringInterpolation: LogInterpolation) {
        self.content = stringInterpolation.content()
    }
    
    // MARK: - Public Properties
    
    /// Plain text content.
    public var description: String {
        content
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case text
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.description, forKey: .text)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.content = try container.decode(String.self, forKey: .text)
    }
    
    public func asString() -> String? {
        content
    }

    public func asData() -> Data? {
        content.asData()
    }
    
    public static func +=(lhs: inout Message, rhs: String) {
        lhs.content.append(rhs)
    }
    
    public static func +=(lhs: inout Message, rhs: Message) {
        lhs.content.append(rhs.content)
    }
    
}
