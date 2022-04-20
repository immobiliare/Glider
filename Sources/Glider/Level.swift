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

extension Log {
    
    /// This enum represent the different log levels defined by `syslog`
    /// (standardized by RFC-5424 <https://tools.ietf.org/html/rfc5424>).
    /// The levels also have a numerical code which is standardized by syslog and is listed below.
    ///
    /// - `emergency`:  System is unusable.
    /// - `alert`:      Action must be taken immediately.
    /// - `critical`:   Logging at this level or higher could have a significant performance cost.
    ///                 The logging system may collect and store enough information such as stack shot etc.
    ///                 that may help in debugging these critical errors.
    /// - `error`:      Error conditions.
    /// - `warning`:    Abnormal conditions that do not prevent the program from completing a specific task.
    ///                 These are meant to be persisted (unless the system runs out of storage quota).
    /// - `notice`:     Conditions that are not error conditions, but that may require special handling
    ///                 or that are likely to lead to an error. These messages will be stored by the logging system
    ///                 unless it runs out of the storage quota.
    /// - `info`:       Informational messages that are not essential for troubleshooting errors.
    ///                 These can be discarded by the logging system, especially if there are resource constraints.
    /// - `debug`:      Messages meant to be useful only during development.
    ///                 This is meant to be disabled in shipping code.
    public enum Level: Int, Comparable, CaseIterable,
                        CustomStringConvertible {
        case emergency = 0
        case alert
        case critical
        case error
        case warning
        case notice
        case info
        case debug

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
            }
        }
        
        public static func < (lhs: Log.Level, rhs: Log.Level) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
    }
    
}

// MARK: - Extension

extension Log.Level {
        
    /// Return `true` when receiver level is more severe than passed level argument.
    ///
    /// - Parameter than: comparision level.
    /// - Returns: `Bool`
    @inlinable
    public func isMoreSevere(than: Log.Level) -> Bool {
        self.rawValue < than.rawValue
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
        }
    }
    
}
