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
import os.log

/// Represent the different log severity levels defined by the Glider SDK.
/// Lower level means an higher severity (`emergency` is equal to `0`, `trace` equals to `8`)
///
/// This is standardized by [RFC-5424](https://tools.ietf.org/html/rfc5424)
/// also used by Apple's [swift-log](https://github.com/apple/swift-log).
/// Discussion can be found
/// [here](https://forums.swift.org/t/logging-levels-for-swifts-server-side-logging-apis-and-new-os-log-apis/20365).
///
public enum Level: Int, Comparable, CaseIterable,
                   CustomStringConvertible, Codable {
    
    /// Application/system is unusable.
    case emergency = 0
    
    /// Action must be taken immediately.
    case alert
    
    /// Logging at this level or higher could have a significant performance cost.
    /// The logging system may collect and store enough information such as stack shot etc.
    /// that may help in debugging these critical errors.
    case critical
    
    /// Error conditions.
    case error
    
    /// Abnormal conditions that do not prevent the program from completing a specific task.
    /// These are meant to be persisted (unless the system runs out of storage quota).
    case warning
    
    /// Conditions that are not error conditions, but that may require special handling
    /// or that are likely to lead to an error. These messages will be stored by the logging system
    /// unless it runs out of the storage quota.
    case notice
    
    /// Informational messages that are not essential for troubleshooting errors.
    /// These can be discarded by the logging system, especially if there are resource constraints.
    case info
    
    /// Messages meant to be useful only during development.
    /// This is meant to be disabled in shipping code.
    case debug
    
    /// Trace messages.
    case trace
    
    /// Readable description of the level.
    public var description: String {
        switch self {
        case .emergency:    return "emergency"
        case .alert:        return "alert"
        case .critical:     return "critical"
        case .error:        return "error"
        case .warning:      return "warning"
        case .notice:       return "notice"
        case .info:         return "info"
        case .debug:        return "debug"
        case .trace:        return "trace"
        }
    }
    
    public static func < (lhs: Level, rhs: Level) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
}


// MARK: - Extension

extension Level {
    
    /// Return `true` when receiver level is more severe than passed level argument.
    /// If receiver is `nil` the function return false.
    ///
    /// - Parameter comparisonLevel: comparision level.
    /// - Returns: `Bool`
    @inlinable
    public func isMoreSevere(than comparisonLevel: Level?) -> Bool {
        guard let comparisonLevel = comparisonLevel else {
            return false
        }

        return self.rawValue < comparisonLevel.rawValue
    }
    
    /// Return `true` if receiver level should be accepted with passed `minLevel`.
    /// If `minLevel` is `nil` it return `true`.
    ///
    /// - Parameter minLevel: minimum level accepted.
    /// - Returns: `Bool`
    internal func isAcceptedWithMinimumLevelSet(minLevel: Level?) -> Bool {
        guard let minLevel = minLevel else {
            return true
        }

        return self.rawValue < minLevel.rawValue
    }
    
    /// Return the os_log compatible representation of the severity level.
    ///
    /// NOTE:
    /// The levels such as notice, warning, critical and above do not have a namesake in the system.
    /// They will be mapped on to levels that closely matches their recommendation.
    /// In this case the following map is used:
    /// - `notice` ~> `info`
    /// - `warning` ~> `error`
    /// - `emergency`, `critical`, `alert` ~> `fault`
    public var osLogLevel: OSLogType {
        switch self {
        case .emergency:    return .fault
        case .alert:        return .fault
        case .critical:     return .fault
        case .error:        return .error
        case .warning:      return .error
        case .notice:       return .info
        case .info:         return .info
        case .debug:        return .debug
        case .trace:        return .debug
        }
    }
    
}
