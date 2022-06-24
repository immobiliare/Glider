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

// MARK: - LogBoolFormatting

public enum LogBoolFormatting {
    case answer
    case truth
    case numeric
}

public enum LogDoubleFormatting {
    case fixed(precision: Int, explicitPositiveSign: Bool)
    case formatter(formatter: Formatter)
    case measure(unit: Unit, options: MeasurementFormatter.UnitOptions, style: Formatter.UnitStyle = .short)
    case bytes(style: ByteCountFormatter.CountStyle)
}

public enum LogDateFormatting {
    case iso8601
    case custom(_ format: String)
}

public enum LogCGModelsFormatting {
    case withPrecision(_ precision: Int)
    case natural
}

// MARK: - LogPrivacy

@frozen
/// `LogPrivacy` can be used as parameter in conjuction with `StringInterpolation` protocol
/// to compose messages which also support privacy.
/// Similar to OSLog, all interpolated values default to a private scope (in a non-DEBUG)
/// environment, with their values redacted.
public struct LogPrivacy: Equatable {
    
    // MARK: - Public Properties

    /// Masking when privacy is set.
    /// - `hash`: use hashing function to compose the value.
    /// - `none`: no mask set.
    public enum Mask: Equatable {
        case hash
        case none
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
    
    /// Private with mask set.
    ///
    /// - Parameter mask: set mask.
    /// - Returns: LogPrivacy
    public static func `private`(mask: Mask) -> LogPrivacy {
        LogPrivacy(isPrivate: true, mask: mask)
    }

    #if DEBUG
    internal static var disableRedaction: Bool = true
    #endif

    internal static let redacted = "<redacted>"
    
}
