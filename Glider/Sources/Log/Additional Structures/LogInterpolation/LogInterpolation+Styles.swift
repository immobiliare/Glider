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

// MARK: - Bool

/// Boolean formatting types.
/// - `answer`: `yes` or `no`.
/// - `truth`: `true` or `false`.
/// - `numeric`: `1` or `0`.
public enum LogBoolFormatting {
    case answer
    case truth
    case numeric
}

// MARK: - Int

/// Integer formatting types.
/// - `decimal`: decimal formatter with optional max/min digits.
/// - `formatter`: use custom formatter instance.
public enum LogIntegerFormatting {
    case decimal(minDigits: Int? = nil, maxDigits: Int? = nil)
    case formatter(NumberFormatter)
    
    /// Default formatting.
    public static let `default`: LogIntegerFormatting = .decimal(minDigits: nil, maxDigits: nil)
}

// MARK: - Double

/// Double types formatting types.
/// - `fixed`: fixed with precision of fraction number.
/// - `formatter`: custom formatter instance to use.
/// - `measure`: format using specified unit of measure.
/// - `currency`: format a currency value.
/// - `bytes`: format bytes value.
public enum LogDoubleFormatting {
    case fixed(precision: Int)
    case formatter(formatter: Formatter)
    case measure(unit: Unit, options: MeasurementFormatter.UnitOptions, style: Formatter.UnitStyle = .short)
    case currency(symbol: String?, usesGroupingSeparator: Bool = true)
    case bytes(style: ByteCountFormatter.CountStyle)
    
    /// Default formatting.
    public static let `default`: LogDoubleFormatting = .fixed(precision: 2)
}

// MARK: - Date

/// Date formatting types.
/// - `iso8601`: format using ISO-8601 specs.
/// - `custom`: format date using custom format options.
public enum LogDateFormatting {
    case iso8601
    case custom(_ format: String, locale: Locale = GliderSDK.shared.locale)
}

// MARK: - LogPrivacy

/// `LogPrivacy` can be used as parameter in conjuction with `StringInterpolation` protocol
/// to compose messages which also support privacy.
/// Similar to OSLog, all interpolated values default to a private scope (in a non-DEBUG)
/// environment, with their values redacted.
@frozen public struct LogPrivacy: Equatable {
    
    // MARK: - Public Properties

    /// Masking when privacy is set.
    /// - `hash`: use hashing function to compose the value.
    /// - `none`: no mask set.
    public enum Mask: Equatable {
        case hash
        case none
        case partiallyHide
    }

    /// Is private privacy flag set.
    public var isPrivate: Bool
    
    // MARK: - Private Properties
    
    /// Masking for privacy attribute.
    private let mask: Mask?
    
    // MARK: - Public Properties
    
    /// Privacy is not set.
    public static var `public`: LogPrivacy {
        LogPrivacy(isPrivate: false, mask: nil)
    }
    
    /// Private mask is set.
    public static var `private`: LogPrivacy {
        LogPrivacy(isPrivate: true, mask: nil)
    }
    
    /// Private mask is set.
    public static var `partiallyHide`: LogPrivacy {
        LogPrivacy(isPrivate: true, mask: .partiallyHide)
    }
    
    /// Private with mask set.
    ///
    /// - Parameter mask: set mask.
    /// - Returns: LogPrivacy
    public static func `private`(mask: Mask) -> LogPrivacy {
        LogPrivacy(isPrivate: true, mask: mask)
    }

    internal static let redacted = "<redacted>"
    
}
