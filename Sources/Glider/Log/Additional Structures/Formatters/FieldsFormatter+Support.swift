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
import SwiftUI

extension FieldsFormatter {
    
    /// Represent a single elemnt of the formatter strings to produce.
    /// Each `Field` represent a log attribute to print along with their options and styles.
    public struct Field {
        public typealias Configure = ((inout Field) -> Void)

        // MARK: - Public Properties
        
        /// Represented field key.
        public let field: FieldIdentifier
        
        /// Optionally truncate the output string.
        /// By default is set to `nil` which means no truncation is applied.
        public var truncate: String.TruncationStyle?
        
        /// Pad to the specified width and style, `nil` to avoid padding.
        public var padding: String.PaddingStyle?
        
        /// Optional string transform functions, evaluated in prder.
        public var transforms: [String.Transform]?
        
        /// Some formatters (like the `JSONFormatter`= uses this value to print the field's readable label.
        public var label: String?
        
        /// For array and dictionaries (like extra or tags) you can specify a format where the content is
        /// encapsulasted (for example `keys={%@}` for tags will produce something like `keys={k1=v1,k2=v2}`).
        public var format: String?
        
        /// When encoding a field which contains array or dictionary the item separator is used to compose the string.
        public var separator: String = ","
        
        // MARK: - Initialization
               
        /// Initialize a new `FieldsFormatter` with given identifier and an optional
        /// configuration callback.
        ///
        /// - Parameters:
        ///   - field: field identifier.
        ///   - configure: configuration callback.
        internal init(_ field: FieldIdentifier, _ configure: Configure?) {
            self.field = field
            configure?(&self)
        }
        
        public static func field(_ field: FieldIdentifier, _ configure: Configure? = nil) -> Field {
            self.init(field, configure)
        }
        
        public static func timestamp(style: TimestampStyle, _ configure: Configure? = nil) -> Field {
            self.init(.timestamp(style), configure)
        }
        
        public static func level(style: LevelStyle, _ configure: Configure? = nil) -> Field {
            self.init(.level(style), configure)
        }
        
        public static func callSite( _ configure: Configure? = nil) -> Field {
            self.init(.callSite, configure)
        }
        
        public static func callingThread(style: CallingThreadStyle,  _ configure: Configure? = nil) -> Field {
            self.init(.callingThread(style), configure)
        }
        
        public static func processName( _ configure: Configure? = nil) -> Field {
            self.init(.processName, configure)
        }

        public static func processID( _ configure: Configure? = nil) -> Field {
            self.init(.processID, configure)
        }
        
        public static func delimiter(style: DelimiterStyle, _ configure: Configure? = nil) -> Field {
            self.init(.delimiter(style), configure)
        }
        
        public static func literal(_ value: String, _ configure: Configure? = nil) -> Field {
            self.init(.literal(value), configure)
        }
        
        public static func tags(keys: [String]?, _ configure: Configure? = nil) -> Field {
            var field = self.init(.tags(keys), configure)
            field.format = "tags={%@}"
            return field
        }
        
        public static func extra(keys: [String]?, _ configure: Configure? = nil) -> Field {
            var field = self.init(.extra(keys), configure)
            field.format = "extra={%@}"
            return field
        }
        
        public static func custom(_ callback: @escaping CallbackFormatter.Callback, _ configure: Configure? = nil) -> Field {
            let formatter = CallbackFormatter(callback)
            return self.init(.custom(formatter), configure)
        }
        
        public static func category( _ configure: Configure? = nil) -> Field {
            self.init(.category, configure)
        }
        
        public static func subsystem( _ configure: Configure? = nil) -> Field {
            self.init(.subsystem, configure)
        }
        
        public static func eventUUID( _ configure: Configure? = nil) -> Field {
            self.init(.eventUUID, configure)
        }
        
        public static func message( _ configure: Configure? = nil) -> Field {
            self.init(.message, configure)
        }
        
        public static func userId( _ configure: Configure? = nil) -> Field {
            self.init(.userId, configure)
        }
        
        public static func username( _ configure: Configure? = nil) -> Field {
            self.init(.username, configure)
        }
        
        public static func ipAddress( _ configure: Configure? = nil) -> Field {
            self.init(.ipAddress, configure)
        }
        
        public static func userData(keys: [String]? = nil, _ configure: Configure? = nil) -> Field {
            var field = self.init(.userData(keys), configure)
            field.format = "userData={%@}"
            return field
        }
        
        public static func fingerprint(_ configure: Configure? = nil) -> Field {
            self.init(.fingerprint, configure)
        }
        
        public static func objectMetadata(keys: [String]? = nil, _ configure: Configure? = nil) -> Field {
            var field = self.init(.objectMetadata(keys), configure)
            field.format = "metadata={%@}"
            return field
        }
        
        public static func object() -> Field {
            self.init(.object, nil)
        }
        
        // MARK: - Internal Function
        
        internal func value(forEvent event: Event) -> String? {
            nil
        }
        
    }
    
    /// Represent the individual key of a formatted log when using
    /// the `FieldsFormatter` formatter.
    ///
    /// - `category`: category identifier of the parent's log.
    /// - `subsystem`: subsystem identifier of the parent's log.
    /// - `eventUUID`: identifier of the event, autoassigned.
    /// - `timestamp`: creation data of the event.
    /// - `level`: level of severity for the event.
    /// - `callSite`: line and file of the caller.
    /// - `stackFrame`: which function called the event.
    /// - `callingThread`: calling of the thread.
    /// - `processName`: name of the process.
    /// - `processID`: PID of the process.
    /// - `message`: text message of the event.
    /// - `userId`: when assigned the currently logged user id which generate the event.
    /// - `userEmail`: when assigned the currently logged user email which generate the event.
    /// - `username`: when assigned the currently logged username which generate the event.
    /// - `ipAddress`: if set the assigned logged user's ip address which generate the event.
    /// - `userData`: `keys` values for given `keys` found in user's data.
    /// - `fingerprint`: the fingerprint used for event, if not found the `scope`'s fingerprint.
    /// - `objectMetadata`: a json string representation of the event's associated object metadata.
    /// - `objectMetadataKeys`: `keys` values for given `keys` found in associated object's metadata.
    /// - `delimiter`: delimiter.
    /// - `tags`: `keys` values for given `keys` found in event's `tags`.
    /// - `extra`: `keys` values for given `keys` found in event's `extra`.
    /// - `custom`: apply custom tranformation function which receive the `event` instance.
    public enum FieldIdentifier {
        case category
        case subsystem
        case eventUUID
        case timestamp(TimestampStyle)
        case level(LevelStyle)
        case callSite
        case stackFrame
        case callingThread(CallingThreadStyle)
        case processName
        case processID
        case message
        case userId
        case userEmail
        case username
        case ipAddress
        case userData([String]?)
        case fingerprint
        case objectMetadata([String]?)
        case object
        case delimiter(DelimiterStyle)
        case literal(String)
        case tags([String]?)
        case extra([String]?)
        case custom(EventFormatter)
        
        internal var defaultLabel: String? {
            switch self {
            case .category: return "category"
            case .subsystem: return "subsystem"
            case .eventUUID: return "uuid"
            case .timestamp: return "timestamp"
            case .level: return "level"
            case .callSite: return "callSite"
            case .stackFrame: return "stackFrame"
            case .callingThread: return "callingThread"
            case .processName: return "processName"
            case .processID: return "processID"
            case .message: return "message"
            case .userId: return "userId"
            case .userEmail: return "userEmail"
            case .username: return "username"
            case .ipAddress: return "ip"
            case .userData: return "userData"
            case .object: return "object"
            case .fingerprint: return "fingerprint"
            case .objectMetadata: return "objectMetadata"
            case .tags: return "tags"
            case .extra: return "extra"
            default: return nil
            }
        }
    }
    
    /// The timestamp style used to format dates.
    /// - `iso8601`: Specifies a timestamp style that uses the date format string "yyyy-MM-dd HH:mm:ss.SSS zzz".
    /// - `unix`: Specifies a UNIX timestamp indicating the number of seconds elapsed since January 1, 1970.
    /// - `custom`: Specifies a custom date format.
    public enum TimestampStyle {
        case iso8601
        case unix
        case custom(String)
    }
    
    /// Specifies the manner in which `Level` values should be rendered.
    public enum LevelStyle {
        case simple
        case short
        case emoji
        case numeric
        case custom((Level) -> String)
    }
    
    /// Specify how `Level` value should be represented in text.
    /// - `capitalized`: Specifies that the `Level` should be output as a human-readable word
    ///                  with the initial capitalization.
    /// - `lowercase`: Specifies that the `Level` should be output as a human-readable word
    ///                 in all lowercase characters.
    /// - `uppercase`: Specifies that the `Level` should be output as a human-readable word in
    ///                all uppercase characters.
    /// - `numeric`: Specifies that the `rawValue` of the `Level` should be output as an integer within a string.
    /// - `colorCoded`: Specifies that the `rawValue` of the `LogSeverity` should be output as an emoji character
    ///                 whose color represents the level of severity.
    public enum TextRepresentation {
        case capitalize
        case lowercase
        case uppercase
        case numeric
        case colorCoded
    }
    
    public enum CallingThreadStyle {
        case hex
        case integer
    }
    
    public enum DelimiterStyle {
        case spacedPipe
        case spacedHyphen
        case tab
        case space
        case `repeat`(Character,Int)
        case custom(String)
        
        internal var delimiter: String {
            switch self {
            case .spacedPipe:
                return " | "
            case .spacedHyphen:
                return " - "
            case .tab:
                return "\t"
            case .space:
                return " "
            case .custom(let sep):
                return sep
            case .repeat(let char, let count):
                return String(repeating: char, count: count)
            }
        }
    }
    
}

// MARK: - Foundation Extension

extension DateFormatter {
        
    /// Internal date formatter.
    fileprivate static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    /// Internal ISO8601 date formatter.
    fileprivate static var iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
    
}

extension Date {
    
    internal func format(style: FieldsFormatter.TimestampStyle) -> String? {
        switch style {
        case .custom(let format):
            DateFormatter.dateFormatter.dateFormat = format
            return DateFormatter.dateFormatter.string(from: self)
        case .iso8601:
            return DateFormatter.iso8601Formatter.string(from: self)
        case .unix:
            return String(self.timeIntervalSince1970)
        }
    }
    
}

// MARK: - Level Extension

extension Level {
    
    internal func format(style: FieldsFormatter.LevelStyle) -> String? {
        switch style {
        case .numeric:
            return String(describing: rawValue)
        case .simple:
            return description
        case .emoji:
            return emoji
        case .short:
            return shortDescription
        case .custom(let formatter):
            return formatter(self)
        }
    }

    internal var emoji: String {
        switch self {
        case .debug:        return "▫️"
        case .info:         return "▪️"
        case .notice:       return "🔷"
        case .warning:      return "🔶"
        case .error:        return "✴️"
        case .critical:     return "❌"
        case .alert:        return "✴️"
        case .emergency:    return "🆘"
        }
    }
    
    internal var shortDescription: String {
        switch self {
        case .emergency: return "EMRG"
        case .alert:     return "ALRT"
        case .critical:  return "CRTC"
        case .error:     return "ERRR"
        case .warning:   return "WARN"
        case .notice:    return "NTCE"
        case .info:      return "INFO"
        case .debug:     return "DEBG"
        }
    }
    
}

// MARK: - FieldsFormatter.CallingThreadStyle

extension FieldsFormatter.CallingThreadStyle {
    
    /// Format the calling thread based upon given style.
    ///
    /// - Parameter callingThreadID: thread id to format.
    /// - Returns: String
    internal func format(_ callingThreadID: UInt64) -> String {
        switch self {
        case .hex:      return String(format: "%08X", callingThreadID)
        case .integer:  return String(describing: callingThreadID)
        }
    }

}
