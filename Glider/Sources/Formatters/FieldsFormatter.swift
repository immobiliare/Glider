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

/// `FieldsFormatter` is used to format log messages using specified fields you can
/// compose in a custom format.
public class FieldsFormatter: EventFormatter {
    
    // MARK: - Public Properties
    
    /// Formatted fields used to create the string.
    public var fields: [Field]
    
    // MARK: - Initialization
    
    /// Initialize with a list of given fields used to format the event.
    ///
    /// - Parameter fields: fields.
    public init(fields: [Field]) {
        self.fields = fields
    }
    
    /// Return the default log formatter.
    /// It's composed by:
    ///     - timestamp as ISO8601 padded right with 20 chars
    ///     - a pipe
    ///     - short event's severity level
    ///     - delimiter with space
    ///     - message
    ///
    /// Example:
    ///     `2022-05-24T13:20:52Z | INFO test message one`
    /// - Returns: `FieldsFormatter`
    open class func `default`() -> FieldsFormatter {
        FieldsFormatter(fields: [
            .timestamp(style: .xcode, {
                $0.padding = .left(columns: 22)
            }),
            .custom({
                " [\($0.label ?? Bundle.appName)]"
            }),
            .level(style: .emoji, {
                $0.stringFormat = " %@ "
            }),
            .message()
        ])
    }
    
    // MARK: - Public Functions
    
    open func format(event: Event) -> SerializableData? {
        return valuesForEvent(event: event).reduce(into: String()) { partialResult, fieldValue in
            if let fieldValue = fieldValue {
                partialResult.append(fieldValue)
            }
        }
    }
    
    open func valuesForEvent(event: Event) -> [String?] {
        fields.map { field in
            guard let value = event.valueForFormatterField(field),
                  var stringifiedValue = field.format.stringify(value, forField: field) else {
                return nil
            }
            
            // Custom text transform
            for transform in field.transforms ?? [] {
                stringifiedValue = transform(stringifiedValue)
            }
            
            var stringValue = stringifiedValue.trunc(field.truncate).padded(field.padding)
            if let format = field.stringFormat {
                stringValue = String.format(format, value: stringValue)
            }
            return stringValue
        }
        
    }
    
}

// MARK: - Event Extension

internal extension Event {
    
    func valueForFormatterField(_ field: FieldsFormatter.Field) -> Any? {
        switch field.field {
        case .timestamp(let style):
            return timestamp.format(style: style)
            
        case .level(let style):
            return level.format(style: style)
            
        case .callSite:
            let file = (scope.fileName as NSString?)?.pathComponents.last ?? "redacted"
            let line = (scope.fileLine != nil ? "\(scope.fileLine!)" : "-")
            return "\(file):\(line)"
            
        case .stackFrame:
            return scope.function
            
        case .callingThread(let style):
            return style.format(scope.threadID)
            
        case .processName:
            return ProcessIdentification.shared.processName
            
        case .processID:
            return String(ProcessIdentification.shared.processID)
            
        case .message:
            return message.description
            
        case .object:
            return serializedObjectData
            
        case .objectMetadata(let keys):
            return serializedObjectMetadata?.filteredByKeys(keys)

        case .delimiter(let style):
            return style.delimiter
            
        case .literal(let value):
            return value
            
        case .tags(let keys):
            return allTags?.filteredByKeys(keys)
            
        case .extra(let keys):
            return allExtra?.filteredByKeys(keys)

        case .custom(let formatter):
            return formatter.format(event: self)
            
        case .category:
            return category?.description
        
        case .subsystem:
            return subsystem?.description
            
        case .eventUUID:
            return id
            
        case .userId:
            return scope.user?.userId
            
        case .userEmail:
            return scope.user?.username
            
        case .username:
            return scope.user?.username
            
        case .ipAddress:
            return scope.user?.userId
            
        case .userData(let keys):
            return scope.user?.data?.filteredByKeys(keys)
            
        case .fingerprint:
            return fingerprint ?? scope.fingerprint
            
        case .customValue(let function):
            return function(self)
            
        }
    }
    
}

// MARK: - Callback Based Event Formatter

public class CallbackFormatter: EventFormatter {
    public typealias Callback = ((Event) -> String?)

    // MARK: - Public Properties
        
    public var callback: Callback
    
    // MARK: - Initialization
    
    public init(_ callback: @escaping Callback) {
        self.callback = callback
    }
    
    // MARK: - Public Functions
    
    public func format(event: Event) -> SerializableData? {
        callback(event)
    }
    
}

extension Dictionary {
    
    func filteredByKeys(_ keys: [Key]?) -> Dictionary {
        guard let keys = keys else {
            return self
        }

        let filteredKeys = Set(keys)
        return filter {
            filteredKeys.contains($0.key)
        }
    }
    
}
