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

extension String.StringInterpolation {
    
    /// Defines interpolation for expressions of type `String`
    public mutating func appendInterpolation(_ value: String,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        appendLiteral(value.privacy(privacy).padded(pad))
    }
 
    /// Defines interpolation for expressions of type `Bool`
    public mutating func appendInterpolation(_ value: Bool,
                                             format: LogBoolFormatting? = nil,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        appendLiteral(value.format(format).privacy(privacy).padded(pad))
    }
    
    /// Defines interpolation for expressions of type `Double`
    public mutating func appendInterpolation(_ value: Double,
                                             format: LogDoubleFormatting? = nil,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        appendLiteral(value.format(format).privacy(privacy).padded(pad))
    }
    
    /// Defines interpolation for expressions of type `Date`
    public mutating func appendInterpolation(_ value: Date,
                                             format: LogDateFormatting? = nil,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        appendLiteral(value.format(format).privacy(privacy).padded(pad))
    }
    
    /// Defines interpolation for expressions of type `[Any]`
    public mutating func appendInterpolation(_ value: CGSize,
                                             format: LogCGModelsFormatting? = nil,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        appendLiteral(value.format(format).privacy(privacy).padded(pad))
    }
   
    /// Defines interpolation for expressions of type `[Any]`
    public mutating func appendInterpolation(_ value: CGFloat,
                                             format: LogCGModelsFormatting? = nil,
                                             pad: String.PaddingStyle? = nil,
                                             privacy: LogPrivacy = .private) {
        appendLiteral(value.format(format).privacy(privacy).padded(pad))
    }
    
}

extension String {
    
    /// Apply privacy scope.
    ///
    /// - Parameter privacy: privacy scope.
    /// - Returns: String
    internal func privacy(_ privacy: LogPrivacy) -> String {
        #if DEBUG
        if LogPrivacy.disableRedaction {
            return String(describing: self)
        }
        #endif
        
        switch privacy {
        case .public:
            return String(describing: self)
        case .private(mask: .hash):
            return "\(String(describing: self).hash)"
        default:
            return LogPrivacy.redacted
        }
    }
    
}

extension Bool {
    
    internal func format(_ format: LogBoolFormatting?) -> String {
        guard let format = format else {
            return String(describing: self)
        }

        switch format {
        case .answer:
            return (self ? "yes": "no")
        case .truth:
            return (self ? "true": "false")
        case .numeric:
            return (self ? "1" : "0")
        }
    }
    
}

extension Double {
    
    internal func format(_ format: LogDoubleFormatting?) -> String {
        guard let format = format else {
            return String(describing: self)
        }
        
        switch format {
        case .fixed(let precision, let explicitPositiveSign):
            return  String(format: "\(explicitPositiveSign ? "+" : "")%.0\(precision)f", self)
            
        case .formatter(let formatter):
            return formatter.string(for: NSNumber(value: self)) ?? ""
            
        case .measure(let unit, let options, let style):
            let formatter = MeasurementFormatter()
            formatter.unitOptions = options
            formatter.unitStyle = style
            formatter.locale = GliderSDK.shared.locale
            return formatter.string(from: .init(value: self, unit: unit))
            
        case .bytes(let style):
            let formatter = ByteCountFormatter()
            formatter.countStyle = style
            return formatter.string(from: .init(value: self, unit: .bytes))
            
        }
    }
    
}

extension Date {
    
    internal func format(_ format: LogDateFormatting?) -> String {
        guard let format = format else {
            return String(describing: self)
        }
        
        switch format {
        case .iso8601:
            let formatter = ISO8601DateFormatter()
            return formatter.string(from: self)
            
        case .custom(let format):
            let formatter = DateFormatter()
            formatter.locale = GliderSDK.shared.locale
            formatter.dateFormat = format
            return formatter.string(from: self)
            
        }
    }
    
}

extension CGSize {
    
    internal func format(_ format: LogCGModelsFormatting?) -> String {
        guard let format = format else {
            return String(describing: self)
        }
        
        switch format {
        case .withPrecision(let precision):
            return "(\(String(format: "%.\(precision)f", width)), \(String(format: "%.\(precision)f", height)))"
        case .natural:
            return "(w:\(String(format: "%.2f", width)), h:\(String(format: "%.2f", height)))"

        }
    }
    
}

extension CGFloat {
    
    internal func format(_ format: LogCGModelsFormatting?) -> String {
        guard let format = format else {
            return String(describing: self)
        }
        
        switch format {
        case .withPrecision(let precision):
            return "\(String(format: "%.\(precision)f"))"
        case .natural:
            return "\(String(format: "%.2f"))"

        }
    }
    
}
