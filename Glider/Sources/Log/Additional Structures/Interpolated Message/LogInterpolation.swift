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
import CoreGraphics

@frozen
public struct LogInterpolation: StringInterpolationProtocol {

    @usableFromInline
    enum Value {
        case literal(String)
        case string(() -> String, pad: String.PaddingStyle?, privacy: LogPrivacy)
        case convertible(() -> CustomStringConvertible, pad: String.PaddingStyle?, privacy: LogPrivacy)
        
        case meta(() -> Any.Type, pad: String.PaddingStyle?, privacy: LogPrivacy)
        case object(() -> NSObject, privacy: LogPrivacy)
        
        case float(() -> Float, format: LogDoubleFormatting, pad: String.PaddingStyle?, privacy: LogPrivacy)
        case double(() -> Double, format: LogDoubleFormatting, pad: String.PaddingStyle?, privacy: LogPrivacy)
        case cgfloat(() -> CGFloat, format: LogCGModelsFormatting, pad: String.PaddingStyle?, privacy: LogPrivacy)
        case cgsize(() -> CGSize, format: LogCGModelsFormatting, pad: String.PaddingStyle?, privacy: LogPrivacy)

        case signedInt(() -> Int64, format: LogIntegerFormatting, pad: String.PaddingStyle?, privacy: LogPrivacy)
        case unsignedInt(() -> UInt64, format: LogIntegerFormatting, pad: String.PaddingStyle?, privacy: LogPrivacy)
        case bool(() -> Bool, format: LogBoolFormatting, privacy: LogPrivacy)

        case date(() -> Date, format: LogDateFormatting, privacy: LogPrivacy)
    }
    
    // MARK: - Private Properties

    private(set) var storage: [Value] = []
    
    // MARK: - Initialization
    
    public init(literal: String? = nil) {
        if let literal = literal {
            appendLiteral(literal)
        }
    }
    
    /// Appends a literal segment to the interpolation.
    public mutating func appendLiteral(_ literal: String) {
        storage.append(.literal(literal))
    }

    // MARK: - StringInterpolationProtocol
    
    public init(literalCapacity: Int, interpolationCount: Int) {
        
    }
    
    // MARK: - Internal Functions
    
    internal func content() -> String {
        var message = ""
        
        for value in storage {
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
    
    
}

// MARK: - `String`, `CustomConvertibleString`

extension LogInterpolation {
    
    public mutating func appendInterpolation(_ value: @autoclosure @escaping () -> SerializableData?,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        storage.append(.literal(value()?.asString() ?? ""))
    }
    
    /// Defines interpolation for expressions of type `String`
    public mutating func appendInterpolation(_ argumentString: @autoclosure @escaping () -> String,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        storage.append(.string(argumentString, pad: pad, privacy: privacy))
    }
    
    /// Defines interpolation for values conforming to `CustomStringConvertible`.
    /// The values are displayed using the description methods on them.
    public mutating func appendInterpolation<T>(_ value: @autoclosure @escaping () -> T,
                                                pad: String.PaddingStyle? = nil,
                                                privacy: LogPrivacy = .private) where T: CustomStringConvertible {
        storage.append(.convertible(value, pad: pad, privacy: privacy))
    }
    
}

// MARK: - `Date`

extension LogInterpolation {
    
    
    /// Defines interpolation for expressions of type `Date`
    public mutating func appendInterpolation(_ boolean: @autoclosure @escaping () -> Date,
                                             format: LogDateFormatting = .iso8601,
                                             privacy: LogPrivacy = .private) {
        storage.append(.date(boolean, format: format, privacy: privacy))
    }
}


// MARK: - `Any.Type`, `NSObject`

extension LogInterpolation {
    
    /// Defines interpolation for meta-types.
    public mutating func appendInterpolation(_ value: @autoclosure @escaping () -> Any.Type,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        storage.append(.meta(value, pad: pad, privacy: privacy))
    }
    
    /// Defines interpolation for expressions of type `NSObject`.
    public mutating func appendInterpolation(_ argumentObject: @autoclosure @escaping () -> NSObject,
                                             privacy: LogPrivacy = .private) {
        storage.append(.object(argumentObject, privacy: privacy))
    }
    
}

// MARK: - `Int`, `UInt`

extension LogInterpolation {
    
    
    /// Defines interpolation for expressions of type `Int`
    public mutating func appendInterpolation<T: SignedInteger>(_ number: @autoclosure @escaping () -> T,
                                                               format: LogIntegerFormatting = .`default`,
                                                               pad: String.PaddingStyle? = nil,
                                                               privacy: LogPrivacy = .private) {
        storage.append(.signedInt({
            Int64(number())
        }, format: format, pad: pad, privacy: privacy))
    }

    /// Defines interpolation for expressions of type `UInt`
    public mutating func appendInterpolation<T: UnsignedInteger>(_ number: @autoclosure @escaping () -> T,
                                                                 format: LogIntegerFormatting = .`default`,
                                                                 pad: String.PaddingStyle? = nil,
                                                                 privacy: LogPrivacy = .private) {
        storage.append(.unsignedInt({
            UInt64(number())
        }, format: format, pad: pad, privacy: privacy))
    }
    
}

// MARK: - `Float`, `CGFloat` and `Double`

extension LogInterpolation {
    
    /// Defines interpolation for expressions of type `Float`
    public mutating func appendInterpolation(_ number: @autoclosure @escaping () -> Float,
                                             format: LogDoubleFormatting = .`default`,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        storage.append(.float(number, format: format, pad: pad, privacy: privacy))
    }
    
    /// Defines interpolation for expressions of type `Double`
    public mutating func appendInterpolation(_ number: @autoclosure @escaping () -> Double,
                                             format: LogDoubleFormatting = .`default`,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        storage.append(.double(number, format: format, pad: pad, privacy: privacy))
    }
    
    /// Defines interpolation for expressions of type `CGFloat`
    public mutating func appendInterpolation(_ number: @autoclosure @escaping () -> CGFloat,
                                             format: LogCGModelsFormatting = .natural,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        storage.append(.cgfloat(number, format: format, pad: pad, privacy: privacy))
    }
    
}

// MARK: - `Bool`

extension LogInterpolation {
    
    /// Defines interpolation for expressions of type `Bool`
    public mutating func appendInterpolation(_ boolean: @autoclosure @escaping () -> Bool,
                                             format: LogBoolFormatting = .truth,
                                             privacy: LogPrivacy = .private) {
        storage.append(.bool(boolean, format: format, privacy: privacy))
    }
    
}
