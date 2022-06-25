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

extension Event {
    
    /// Represent the message of a log.
    /// We have used a custom object instead of plain `String` to supports custom object interpolations
    /// via `StringInterpolationProtocol` (we have choosed to not implement interpolation methods directly
    /// on `String` object in order to avoid confusion).
    /// When coded the message itself it's just a literal and loose the composed values.
    public struct Message: ExpressibleByStringInterpolation, ExpressibleByStringLiteral, CustomStringConvertible, Codable {
        
        // MARK: - Public Properties
        
        /// Store the interpolation objects.
        public var interpolation: LogInterpolation

        // MARK: - Initializzation
        
        public init(stringLiteral value: String) {
            interpolation = LogInterpolation(literal: value)
        }

        public init(stringInterpolation: LogInterpolation) {
            interpolation = stringInterpolation
        }
        
        // MARK: - Public Properties
        
        /// Return the composed message.
        public var description: String {
            var message = ""
            
            for value in interpolation.storage {
                switch value {
                case .literal(let value):
                    message.append(value)

                case .string(let value, let pad, let privacy):
                    message.append(value().padded(pad).privacy(privacy))

                case .convertible(let value, let pad, let privacy):
                    message.append(value().description.padded(pad).privacy(privacy))

                case .meta(let value, let pad, let privacy):
                    message.append(String(describing: value()).padded(pad).privacy(privacy))

                case .object(let value, let privacy):
                    message.append(String(describing: value()).privacy(privacy))

                case .float(let value, let format, let pad, let privacy):
                    message.append(Double.format(value: NSNumber(value: value()), format).padded(pad).privacy(privacy))
                    
                case .double(let value, let format, let pad, let privacy):
                    message.append(Double.format(value: NSNumber(value: value()), format).padded(pad).privacy(privacy))

                case .cgfloat(let value, let format, let pad, let privacy):
                    message.append(value().format(format).padded(pad).privacy(privacy))
                    
                case .cgsize(let value, let format, let pad, let privacy):
                    message.append(value().format(format).padded(pad).privacy(privacy))

                case .signedInt(let value, let format, let pad, let privacy):
                    switch format {
                    case let .decimal(minDigits, explicitPositiveSign):
                        message.append(String(format: "\(explicitPositiveSign ? "+" : "")%0\(minDigits)ld", value()).padded(pad).privacy(privacy))
                    }
                    
                case .unsignedInt(let value, let format, let pad,  let privacy):
                    switch format {
                    case let .decimal(minDigits, explicitPositiveSign):
                        message.append(String(format: "\(explicitPositiveSign ? "+" : "")%0\(minDigits)ld", value()).padded(pad).privacy(privacy))
                    }
                    
                case .bool(let value, let format, let privacy):
                    message.append(value().format(format).privacy(privacy))
                    
                case .date(let value, let format, let privacy):
                    message.append(value().format(format).privacy(privacy))
                    
                }
            }
            
            return message
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
            let text = try container.decode(String.self, forKey: .text)
            self.interpolation = .init(literal: text)
        }

    }
    
}
