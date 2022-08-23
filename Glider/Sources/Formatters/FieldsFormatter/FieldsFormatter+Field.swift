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

extension FieldsFormatter {
    
    /// Represent a single attribute to ahow in a `FieldFormatter` instance.
    /// Each `Field` represent an `event` attribute to print according
    /// to a specific representation and formatting attributes.
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
        
        /// Readable label for field.
        ///
        /// NOTE:
        /// Some formatters (like the `JSONFormatter`= uses this value to print the field's readable label.
        public var label: String?
        
        /// Colors to apply to the string.
        ///
        /// Keep in mind: it works only for certain formatters (like `XCodeFormatter` and `TerminalFormatter` where
        /// colorization is supported. Some formatters may ignore this value.
        public var colors: [FieldsFormatterColor]?
        
        /// For array and dictionaries (like `extra` or `tags`) you can specify a format to write the content.
        ///
        /// By default is set to `auto`.
        public var format: StructureFormatStyle = .serializedJSON
        
        /// When encoding a field which contains array or dictionary the item separator is used to compose the string.
        public var separator: String = ","
        
        /// Allows you to further customize the `Field` options per single message received.
        ///
        /// You can, for example, customize the message color based upon severity level
        /// (see `XCodeFormatter` for an example).
        /// You can customize the received `Field` instance which is a copy of self.
        public var onCustomizeForEvent: ((Event, inout Field) -> Void)?
        
        // MARK: - Internal Properties
        
        /// Specify a prefix literal to format the result of formatted.
        /// For example (`extra = { %@ }` uses the format and replace the placeholder with the value formatted.
        ///
        /// By default is set to `nil`•
        public var stringFormat: String?
        
        // MARK: - Initialization
               
        /// Initialize a new `FieldsFormatter` with given identifier and an optional
        /// configuration callback.
        ///
        /// - Parameters:
        ///   - field: field identifier.
        /// - Parameter configure: optional callback to further configure the representation of the data.
        internal init(_ field: FieldIdentifier, _ configure: Configure?) {
            self.field = field
            configure?(&self)
            if self.stringFormat == nil {
                self.stringFormat = self.format.defaultStringFormatForField(field)
            }
        }
        
        /// Create a field to show the `icon` value of an event.
        /// - Parameter configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func icon(_ configure: Configure? = nil) -> Field {
            self.init(.icon, configure)
        }
        
        /// Create a field to show passed field identifier value of an event.
        /// - Parameters:
        ///   - field: field identifier to represent.
        /// - Parameter configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func field(_ field: FieldIdentifier, _ configure: Configure? = nil) -> Field {
            self.init(field, configure)
        }
        
        /// Create a field to show the `label` value of an event.
        /// - Parameter configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func label(_ configure: Configure? = nil) -> Field {
            self.init(.label, configure)
        }
        
        /// Create a field to show the event `timestamp` value of an event.
        /// - Parameters:
        ///   - style: format of the timestamp value.
        ///   - configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func timestamp(style: TimestampStyle, _ configure: Configure? = nil) -> Field {
            self.init(.timestamp(style), configure)
        }
        
        /// Create a field to show the severity `level` value of an event.
        /// - Parameters:
        ///   - style: representation style of the severity level.
        ///   - configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func level(style: LevelStyle, _ configure: Configure? = nil) -> Field {
            self.init(.level(style), configure)
        }
        
        /// Create a field to show the stack trace (caller file, line) of log which produced the event.
        /// - Parameter configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func callSite( _ configure: Configure? = nil) -> Field {
            self.init(.callSite, configure)
        }

        /// Create a field to show the calling thread identifier value of an event.
        /// - Parameters:
        ///   - style: representation style of the calling thread.
        ///   - configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func callingThread(style: CallingThreadStyle, _ configure: Configure? = nil) -> Field {
            self.init(.callingThread(style), configure)
        }
        
        /// Create a field to show the process name of the host app.
        /// - Parameter configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func processName( _ configure: Configure? = nil) -> Field {
            self.init(.processName, configure)
        }
        
        /// Create a field to show the process ID of the host app.
        /// - Parameter configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func processID( _ configure: Configure? = nil) -> Field {
            self.init(.processID, configure)
        }
        
        /// Create a field to show a string literal used as delimiter string.
        /// - Parameters:
        ///   - style: delimiter to use.
        ///   - configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func delimiter(style: DelimiterStyle, _ configure: Configure? = nil) -> Field {
            self.init(.delimiter(style), configure)
        }
        
        /// Create a field to show passed string literal into the field.
        /// - Parameters:
        ///   - value: value of the literal to show.
        ///   - configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func literal(_ value: String, _ configure: Configure? = nil) -> Field {
            self.init(.literal(value), configure)
        }
        
        /// Create a field to show all or a subset of the `tags` of the event.
        /// Use `format` property to define how the data are represented as string.
        /// - Parameters:
        ///   - keys: keys to show, if `nil` all keys are used.
        ///   - configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func tags(keys: [String]?, _ configure: Configure? = nil) -> Field {
            self.init(.tags(keys), configure)
        }
        
        /// Create a field to show all or a subset of the `extra` of the event.
        /// Use `format` property to define how the data are represented as string.
        /// - Parameters:
        ///   - keys: keys to show, if `nil` all keys are used.
        ///   - configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func extra(keys: [String]?, _ configure: Configure? = nil) -> Field {
            self.init(.extra(keys), configure)
        }
        
        /// Create a field to show a string defined by the return value of passed function.
        /// - Parameters:
        ///   - callback: callback producer of the string.
        ///   - configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func custom(_ callback: @escaping CallbackFormatter.Callback,
                                  _ configure: Configure? = nil) -> Field {
            let formatter = CallbackFormatter(callback)
            return self.init(.custom(formatter), configure)
        }
        
        public static func customValue(_ callback: @escaping ((Event?) -> (key: String, value: String)),
                                       _ configure: Configure? = nil) -> Field {
            return self.init(.customValue(callback), configure)
        }
        
        /// Create a field to show the `category` of the parent logger who generated the event.
        ///   - configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func category( _ configure: Configure? = nil) -> Field {
            self.init(.category, configure)
        }
       
        /// Create a field to show the `subsystem` of the parent logger who generated the event.
        ///   - configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func subsystem( _ configure: Configure? = nil) -> Field {
            self.init(.subsystem, configure)
        }
      
        /// Create a field to show the event unique identifier created automatically for the event.
        ///   - configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func eventUUID( _ configure: Configure? = nil) -> Field {
            self.init(.eventUUID, configure)
        }
        
        /// Create a field to show the message text of the event.
        ///   - configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func message( _ configure: Configure? = nil) -> Field {
            self.init(.message, configure)
        }
        
        /// Create a field to show the `id` property of the user set into the scope at the time of event's generation.
        ///   - configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func userId( _ configure: Configure? = nil) -> Field {
            self.init(.userId, configure)
        }
        
        /// Create a field to show the `username` property of the user set into the scope at the time of event's generation.
        ///   - configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func username( _ configure: Configure? = nil) -> Field {
            self.init(.username, configure)
        }
        
        /// Create a field to show the machine's ip address.
        /// - Parameter configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func ipAddress( _ configure: Configure? = nil) -> Field {
            self.init(.ipAddress, configure)
        }
        
        /// Create a field to show some additional data from the currently `scope`'s `user` property of an event.
        /// Use `format` property to define how the data are represented as string.
        /// - Parameters:
        ///   - keys: keys to read.
        ///   - configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func userData(keys: [String]? = nil, _ configure: Configure? = nil) -> Field {
            self.init(.userData(keys), configure)
        }
        
        /// Create a field to show the fingerprint associated to the event.
        /// - Parameter configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func fingerprint(_ configure: Configure? = nil) -> Field {
            self.init(.fingerprint, configure)
        }
        
        /// Create a field to show all/some of the `metadata` associated with the attached `object` of the event.
        /// Use `format` property to define how the data are represented as string.
        ///
        /// - Parameters:
        ///   - keys: keys to read from `metadata`; `nil` to use all available keys.
        ///   - configure: optional callback to further configure the representation of the data.
        /// - Returns: `Field`
        public static func objectMetadata(keys: [String]? = nil, _ configure: Configure? = nil) -> Field {
            self.init(.objectMetadata(keys), configure)
        }
        
        /// Create a field to show the binary (serialized) representation of the `object` to the event.
        /// - Returns: `Field`
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
    public enum FieldIdentifier {
        /// combination of `subsystem` and `category` which identify a log (or app name if not set).
        case label
        /// icon representation of the log as emoji character(s).
        case icon
        /// category identifier of the parent's log.
        case category
        /// subsystem identifier of the parent's log.
        case subsystem
        /// identifier of the event, autoassigned.
        case eventUUID
        /// creation data of the event.
        case timestamp(TimestampStyle)
        /// level of severity for the event.
        case level(LevelStyle)
        /// line and file of the caller.
        case callSite
        /// which function called the event.
        case stackFrame
        /// calling of the thread.
        case callingThread(CallingThreadStyle)
        /// name of the process.
        case processName
        /// PID of the process.
        case processID
        /// text message of the event.
        case message
        /// when assigned the currently logged user id which generate the event.
        case userId
        /// when assigned the currently logged user email which generate the event.
        case userEmail
        /// when assigned the currently logged username which generate the event.
        case username
        /// if set the assigned logged user's ip address which generate the event.
        case ipAddress
        /// `keys` values for given `keys` found in user's data.
        case userData([String]?)
        /// the fingerprint used for event, if not found the `scope`'s fingerprint.
        case fingerprint
        /// a json string representation of the event's associated object metadata.
        case objectMetadata([String]?)
        /// binary object representation
        case object
        /// string literal delimiter
        case delimiter(DelimiterStyle)
        /// literal string.
        case literal(String)
        /// values for keys passed found in `tags` property of an event.
        case tags([String]?)
        /// values for keys passed found in `extra` property of an event.
        case extra([String]?)
        /// apply custom tranformation function which receive the `event` instance.
        case custom(EventMessageFormatter)
        /// custom value.
        case customValue((Event?) -> (key: String, value: String)?)
        
        /// The readable label property of a field.
        internal var defaultLabel: String? {
            switch self {
            case .label: return "label"
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
            case .customValue(let function): return function(nil)?.key
            default: return nil
            }
        }
    }
    
    /// The timestamp style used to format dates.
    /// - `iso8601`: Specifies a timestamp style that uses the date format string "yyyy-MM-dd HH:mm:ss.SSS zzz".
    /// - `unix`: Specifies a UNIX timestamp indicating the number of seconds elapsed since January 1, 1970.
    /// - `xcode`· XCode format (`2009-08-30 04:54:48.128`)
    /// - `custom`: Specifies a custom date format.
    public enum TimestampStyle {
        case iso8601
        case unix
        case xcode
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
        case `repeat`(Character, Int)
        case custom(String)
        
        public var delimiter: String {
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
    
    /// Date formatter for xcode styles
    fileprivate static var xcodeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    /// Internal ISO8601 date formatter.
    fileprivate static var iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
    
}

extension Date {
    
    public func format(style: FieldsFormatter.TimestampStyle) -> String? {
        switch style {
        case .custom(let format):
            DateFormatter.dateFormatter.dateFormat = format
            return DateFormatter.dateFormatter.string(from: self)
        case .iso8601:
            return DateFormatter.iso8601Formatter.string(from: self)
        case .unix:
            return String(self.timeIntervalSince1970)
        case .xcode:
            return DateFormatter.xcodeDateFormatter.string(from: self)
        }
    }
    
}

// MARK: - Level Extension

extension Level {
    
    public func format(style: FieldsFormatter.LevelStyle) -> String? {
        switch style {
        case .numeric:
            return String(describing: rawValue)
        case .simple:
            return description.uppercased()
        case .emoji:
            return emoji
        case .short:
            return shortDescription
        case .custom(let formatter):
            return formatter(self)
        }
    }

    public var emoji: String {
        switch self {
        case .debug, .trace:
            return "⚪️"
        case .info:
            return "🔵"
        case .notice:
            return "🟡"
        case .warning:
            return "🟠"
        case .alert, .emergency, .critical, .error:
            return "🔴"
        }
    }
    
    public var shortDescription: String {
        switch self {
        case .emergency: return "EMRG"
        case .alert:     return "ALRT"
        case .critical:  return "CRTC"
        case .error:     return "ERRR"
        case .warning:   return "WARN"
        case .notice:    return "NTCE"
        case .info:      return "INFO"
        case .debug:     return "DEBG"
        case .trace:     return "TRCE"
        }
    }
    
}

// MARK: - Colorization

public protocol FieldsFormatterColor {
    
    /// Colorize string with self.
    ///
    /// - Parameter string: string to colorize.
    /// - Returns: `String`
    func colorize(_ string: String) -> String
    
}

// MARK: - FieldsFormatter.CallingThreadStyle

extension FieldsFormatter.CallingThreadStyle {
    
    /// Format the calling thread based upon given style.
    ///
    /// - Parameter callingThreadID: thread id to format.
    /// - Returns: String
    public func format(_ callingThreadID: UInt64) -> String {
        switch self {
        case .hex:      return String(format: "%08X", callingThreadID)
        case .integer:  return String(describing: callingThreadID)
        }
    }

}

// MARK: - FieldsFormatter.StructureFormatStyle

extension FieldsFormatter {
        
    /// Defines how the structures like array or dictionaries are encoded
    /// inside the formatted string.
    /// - `serializedJSON`: structure is kept, this is useful when you have a format as JSON which support the
    /// - `list`: as list (a bullet list for each key (example: `\t- key1 = value1\n\t- key2 = value2...`)
    /// - `table`: formatted as table with two columns (one for keys and one for values).
    /// - `queryString`: formatted as query string (example `keys={k1=v1,k2=v2}`)
    public enum StructureFormatStyle {
        case serializedJSON
        case list
        case table
        case queryString
        
        public static var tableInfoMaxColumnsWidth: (keyColumn: Int?, valueColumn: Int?) = (30, 100)
        
        // MARK: - Internal Functions
        
        /// Return the default string format to compose special styles.
        ///
        /// - Parameter title: title of prefix.
        /// - Returns: `String?`
        internal func defaultStringFormatForField(_ field: FieldIdentifier) -> String? {
            switch field {
            case .tags, .extra, .userData, .objectMetadata:
                switch self {
                case .queryString:
                    return "\(field.tableTitle?.lowercased() ?? "")={%@}"
                case .list:
                    return "\(field.tableTitle?.lowercased() ?? "")={%@}"
                case .table:
                    return "\n%@"
                default:
                    return nil
                }
            default:
                return nil
            }
        }
        
        /// Produce a string representation of a complex object based upon the style of the field.
        ///
        /// - Parameters:
        ///   - value: value to format.
        ///   - field: field target.
        /// - Returns: `String?`
        internal func stringify(_ value: Any?, forField field: Field, includeNilKeys: Bool) -> String? {
            guard let value = value else { return nil }

            switch self {
            case .serializedJSON:
                return stringifyAsSerializedJSON(value, forField: field)
            case .list:
                return stringifyAsList(value, forField: field, includeNilKeys: includeNilKeys)
            case .table:
                return stringifyAsTable(value, forField: field, includeNilKeys: includeNilKeys)
            case .queryString:
                return stringifyAsQueryString(value, forField: field, includeNilKeys: includeNilKeys)
            }
        }
        
        // MARK: - Private Functions
        
        private func stringifyAsTable(_ value: Any, forField field: Field, includeNilKeys: Bool) -> String? {
            let keyColumnTitle = field.field.tableTitle?.uppercased() ?? "KEY"
            
            switch value {
            case let stringValue as String:
                return stringValue
            case let dictValue as [String: Any?]:
                let rows: [String] = dictValue.keys.sorted().reduce(into: [String]()) { list, key in
                    if let value = dictValue[key] {
                        if value.isNil == false { // unwrapped has a value
                            list.append(key)
                            
                            let formattedValue = String(describing: value!)
                            list.append(formattedValue)
                        } else if includeNilKeys {
                            list.append(key)
                            list.append("nil")
                        }
                    }
                }
                return createKeyValueTableWithRows(rows, keyColumnTitle: keyColumnTitle)?.stringValue
            case let arrayValue as [Any?]:
                let rows = arrayValue.map({
                    String(describing: $0)
                })
                return createKeyValueTableWithRows(rows, keyColumnTitle: keyColumnTitle)?.stringValue
            default:
                return nil
            }
        }
        
        private func stringifyAsList(_ value: Any, forField field: Field, includeNilKeys: Bool) -> String? {
            switch value {
            case let stringValue as String:
                return stringValue
            case let dictValue as [String: Any?]:
                let value = dictValue.keys.sorted().reduce(into: [String]()) { list, key in
                    if let value = dictValue[key] {
                        if value.isNil == false {
                            list.append("\t- \(key)=\"\(String(describing: value!))\"")
                        } else if includeNilKeys {
                            list.append("\t- \(key)=nil")
                        }
                    }
                }.joined(separator: "\n")
                return "\n\(value)\n"
            case let arrayValue as [Any?]:
                let value = arrayValue.compactMap {
                    guard let value = $0 else {
                        return nil
                    }
                    return "\t - \(String(describing: value))"
                }.joined(separator: "\n")
                return "\n\(value)\n"
            default:
                return nil
            }
        }
        
        private func stringifyAsQueryString(_ value: Any, forField field: Field, includeNilKeys: Bool) -> String? {
            switch value {
            case let stringValue as String:
                return stringValue
            case let dictValue as [String: Any?]:
                guard dictValue.isEmpty == false else {
                    return nil
                }
                
                var components = [String]()
                
                for key in dictValue.keys.sorted() {
                    if let value = dictValue[key] {
                        if value.isNil == false {
                            components.append("\(key)=\(String(describing: value!))")
                        } else if includeNilKeys {
                            components.append("\(key)=nil")
                        }
                    }
                }
                
                return components.joined(separator: "&")
            case let arrayValue as [Any?]:
                guard arrayValue.isEmpty == false else {
                    return nil
                }
                
                return arrayValue.map({ String(describing: $0) }).joined(separator: field.separator)
            default:
                return nil
            }
        }
        
        private func stringifyAsSerializedJSON(_ value: Any, forField field: Field) -> String? {
            switch value {
            case let stringValue as String:
                return stringValue
            case let dictValue as [String: Any?]:                
                let serializableDictionary: [String: SerializableData] = dictValue.compactMapValues({
                    guard let serializable = $0 as? SerializableData else {
                        return nil
                    }
                    
                    return serializable.asString() ?? serializable.asData()
                })
                
                guard serializableDictionary.isEmpty == false else {
                    return nil
                }
                
                let json = try? JSONSerialization.data(withJSONObject: serializableDictionary, options: .sortedKeys)
                return json?.asString()
            case let arrayValue as [Any?]:
                guard arrayValue.isEmpty == false else {
                    return nil
                }
                
                return arrayValue.map({ String(describing: $0) }).joined(separator: field.separator)
            default:
                return String(describing: value)
            }
        }
        
        private func createKeyValueTableWithRows(_ rows: [String], keyColumnTitle: String) -> ASCIITable? {
            guard !rows.isEmpty else {
                return nil
            }
            
            let columnIdentifier = ASCIITable.Column { col in
                col.footer = .init({ footer in
                    footer.border = .BoxDrawn.heavyHorizontal
                })
                col.header = .init(title: keyColumnTitle, { header in
                    header.fillCharacter = " "
                    header.verticalPadding = .init({ padding in
                        padding.top = 0
                        padding.bottom = 0
                    })
                })
                col.verticalAlignment = .top
                col.maxWidth = StructureFormatStyle.tableInfoMaxColumnsWidth.keyColumn
                col.horizontalAlignment = .leading
            }
            
            let columnValues = ASCIITable.Column { col in
                col.footer = .init({ footer in
                    footer.border = .BoxDrawn.heavyHorizontal
                })
                col.header = .init(title: "VALUE", { header in
                    header.fillCharacter = " "
                    header.verticalPadding = .init({ padding in
                        padding.top = 0
                        padding.bottom = 0
                    })
                })
                col.maxWidth =  StructureFormatStyle.tableInfoMaxColumnsWidth.valueColumn
                col.horizontalAlignment = .leading
            }
            
            // split rows in multiple lines when oversize the width of the column
            let formattedRows: [String] = rows.enumerated().map { row in
                let maxColumnWidth = (row.offset % 2 == 0 ? columnIdentifier.maxWidth : columnValues.maxWidth)
                return row.element.split(toWidth: (maxColumnWidth != nil ? maxColumnWidth! - 1 : nil))
            }
            
            let columns = ASCIITable.Column.configureBorders(in: [columnIdentifier, columnValues], style: .light)
            return ASCIITable(columns: columns, content: formattedRows)
        }
        
    }
    
}

// MARK: - String Extension

extension String {
    
    /// Apply transformations specified by the field to the receiver.
    ///
    /// - Parameter field: field.
    /// - Returns: `String`
    public func applyFormattingOfField(_ field: FieldsFormatter.Field) -> String {
        var value = self
        
        // Custom text transforms
        for transform in field.transforms ?? [] {
            value = transform(value)
        }
        
        // Formatting with pad and trucation
        if let format = field.stringFormat {
            value = String.format(format, value: value)
        }
        value = value.trunc(field.truncate)
        value = value.padded(field.padding)
        
        // Apply colorazation (for terminal or xcode if available)
        if let colors = field.colors {
            for color in colors {
                value = color.colorize(value)
            }
        }
        
        return value
    }
    
}
