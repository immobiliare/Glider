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

/// Represent the message of a log.
/// We have used a custom object instead of plain `String` to supports custom object interpolations
/// via `StringInterpolationProtocol` (we have choosed to not implement interpolation methods directly
/// on `String` object in order to avoid confusion).
/// When coded the message itself it's just a literal and loose the composed values.
public struct Message: ExpressibleByStringInterpolation, ExpressibleByStringLiteral, CustomStringConvertible, Codable, SerializableData {
    
    // MARK: - Public Properties
    
    public private(set) var content: String
    
    // MARK: - Initializzation
    
    public init(stringLiteral value: String) {
        self.content = LogInterpolation(literal: value).content()
    }
    
    public init(stringInterpolation: LogInterpolation) {
        self.content = stringInterpolation.content()
    }
    
    // MARK: - Public Properties
    
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

}
