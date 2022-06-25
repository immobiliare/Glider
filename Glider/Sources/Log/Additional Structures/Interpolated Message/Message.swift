//
//  File.swift
//  
//
//  Created by Daniele Margutti on 25/06/22.
//

import Foundation

extension Log {
    
    public struct Message: ExpressibleByStringInterpolation, ExpressibleByStringLiteral, CustomStringConvertible {
        public var interpolation: LogInterpolation

        public init(stringLiteral value: String) {
            interpolation = LogInterpolation(literal: value)
        }

        public init(stringInterpolation: LogInterpolation) {
            interpolation = stringInterpolation
        }

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
