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

@frozen
public struct LogInterpolation: StringInterpolationProtocol {

    @usableFromInline
    enum Value {
        // String
        case literal(String)
        case string(() -> String, trunc: String.TruncationStyle?, pad: String.PaddingStyle?, privacy: LogPrivacy)
        case convertible(() -> CustomStringConvertible, trunc: String.TruncationStyle?, pad: String.PaddingStyle?, privacy: LogPrivacy)
        
        // Objects
        case meta(() -> Any.Type, trunc: String.TruncationStyle?, pad: String.PaddingStyle?, privacy: LogPrivacy)
        case object(() -> NSObject, trunc: String.TruncationStyle?, privacy: LogPrivacy)
        case date(() -> Date, format: LogDateFormatting, trunc: String.TruncationStyle?, pad: String.PaddingStyle?, privacy: LogPrivacy)

        // Numbers
        case float(() -> Float, format: LogDoubleFormatting, trunc: String.TruncationStyle?, pad: String.PaddingStyle?, privacy: LogPrivacy)
        case double(() -> Double, format: LogDoubleFormatting, trunc: String.TruncationStyle?, pad: String.PaddingStyle?, privacy: LogPrivacy)
        case signedInt(() -> Int, format: LogIntegerFormatting, trunc: String.TruncationStyle?, pad: String.PaddingStyle?, privacy: LogPrivacy)
        case unsignedInt(() -> UInt, format: LogIntegerFormatting, trunc: String.TruncationStyle?, pad: String.PaddingStyle?, privacy: LogPrivacy)
        case bool(() -> Bool, format: LogBoolFormatting, privacy: LogPrivacy)
    }
    
    // MARK: - Private Properties

    private(set) var storage = [Value]()
    
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

            case .string(let value, let trunc, let pad, let privacy):
                message.append(value().trunc(trunc).padded(pad).privacy(privacy))

            case .convertible(let value, let trunc, let pad, let privacy):
                message.append(value().description.trunc(trunc).padded(pad).privacy(privacy))

            case .meta(let value, let trunc, let pad, let privacy):
                message.append(String(describing: value()).trunc(trunc).padded(pad).privacy(privacy))

            case .object(let value, let trunc, let privacy):
                message.append(String(describing: value()).trunc(trunc).privacy(privacy))

            case .float(let value, let format, let trunc, let pad, let privacy):
                message.append(Double.format(value: NSNumber(value: value()), format).privacy(privacy).trunc(trunc).padded(pad))
                
            case .double(let value, let format, let trunc, let pad, let privacy):
                message.append(Double.format(value: NSNumber(value: value()), format).privacy(privacy).trunc(trunc).padded(pad))
                
            case .signedInt(let value, let format, let trunc, let pad, let privacy):
                message.append(Int.format(value: NSNumber(value: value()), format).privacy(privacy).trunc(trunc).padded(pad))
                
            case .unsignedInt(let value, let format, let trunc, let pad, let privacy):
                message.append(Int.format(value: NSNumber(value: value()), format).privacy(privacy).trunc(trunc).padded(pad))
                
            case .bool(let value, let format, let privacy):
                message.append(value().format(format).privacy(privacy))
                
            case .date(let value, let format, let trunc, let pad, let privacy):
                message.append(value().format(format).privacy(privacy).trunc(trunc).padded(pad))
                
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
                                             trunc: String.TruncationStyle? = nil,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        storage.append(.string(argumentString, trunc: trunc, pad: pad, privacy: privacy))
    }
    
    /// Defines interpolation for values conforming to `CustomStringConvertible`.
    /// The values are displayed using the description methods on them.
    public mutating func appendInterpolation<T>(_ value: @autoclosure @escaping () -> T,
                                                trunc: String.TruncationStyle? = nil,
                                                pad: String.PaddingStyle? = nil,
                                                privacy: LogPrivacy = .private) where T: CustomStringConvertible {
        storage.append(.convertible(value, trunc: trunc, pad: pad, privacy: privacy))
    }
    
}

// MARK: - `Date`

extension LogInterpolation {
    
    /// Defines interpolation for expressions of type `Date`
    public mutating func appendInterpolation(_ boolean: @autoclosure @escaping () -> Date,
                                             format: LogDateFormatting = .iso8601,
                                             trunc: String.TruncationStyle? = nil,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        storage.append(.date(boolean, format: format, trunc: trunc, pad: pad, privacy: privacy))
    }
}


// MARK: - `Any.Type`, `NSObject`

extension LogInterpolation {
    
    /// Defines interpolation for meta-types.
    public mutating func appendInterpolation(_ value: @autoclosure @escaping () -> Any.Type,
                                             trunc: String.TruncationStyle? = nil,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        storage.append(.meta(value, trunc: trunc, pad: pad, privacy: privacy))
    }
    
    /// Defines interpolation for expressions of type `NSObject`.
    public mutating func appendInterpolation(_ argumentObject: @autoclosure @escaping () -> NSObject,
                                             trunc: String.TruncationStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        storage.append(.object(argumentObject, trunc: trunc, privacy: privacy))
    }
    
}

// MARK: - `Int`, `UInt`

extension LogInterpolation {
    
    public mutating func appendInterpolation(_ number: @autoclosure @escaping () -> Int,
                                             format: LogIntegerFormatting = .`default`,
                                             trunc: String.TruncationStyle? = nil,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        storage.append(.signedInt(number, format: format, trunc: trunc, pad: pad, privacy: privacy))
    }
    
    public mutating func appendInterpolation(_ number: @autoclosure @escaping () -> UInt,
                                             format: LogIntegerFormatting = .`default`,
                                             trunc: String.TruncationStyle? = nil,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        storage.append(.unsignedInt(number, format: format, trunc: trunc, pad: pad, privacy: privacy))
    }
    
}

// MARK: - `Float`, `Double`

extension LogInterpolation {
    
    /// Defines interpolation for expressions of type `Float`
    public mutating func appendInterpolation(_ number: @autoclosure @escaping () -> Float,
                                             format: LogDoubleFormatting = .`default`,
                                             trunc: String.TruncationStyle? = nil,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        storage.append(.float(number, format: format, trunc: trunc, pad: pad, privacy: privacy))
    }
    
    /// Defines interpolation for expressions of type `Double`
    public mutating func appendInterpolation(_ number: @autoclosure @escaping () -> Double,
                                             format: LogDoubleFormatting = .`default`,
                                             trunc: String.TruncationStyle? = nil,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        storage.append(.double(number, format: format, trunc: trunc, pad: pad, privacy: privacy))
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
