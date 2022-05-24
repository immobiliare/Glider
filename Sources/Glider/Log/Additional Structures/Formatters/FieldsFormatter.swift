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
    
    // MARK: - Public Functions
    
    open func format(event: Event) -> String? {
        let values: [String?] = fields.map { field in
            guard var value = event.valueForFormatterField(field) else {
                return nil
            }
            
            // Custom text transform
            for transform in field.transforms ?? [] {
                value = transform(value)
            }
            
            return value.trunc(field.truncate).padded(field.padding)
        }
        
        // Compose string
        return values.reduce(into: String()) { partialResult, fieldValue in
            if let fieldValue = fieldValue {
                partialResult.append(fieldValue)
            }
        }
    }
    
}

fileprivate extension Event {
    
    func valueForFormatterField(_ field: FieldsFormatter.Field) -> String? {
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
            return message
            
        case .objectMetadata:
            guard let json = serializedObject?.metadata,
                  let rawJSON = try? JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed),
                  let rawJSONString = String(data: rawJSON, encoding: .utf8) else {
                      return nil
                  }
            
            return rawJSONString
            
        case .objectMetadataKeys(let prefix, let keys, let separator):
            return (prefix ?? "") + keys
                .compactMap( { serializedObject?.metadata?[$0] as? String })
                .joined(separator: separator)
            
        case .delimiter(let style):
            return style.delimiter
            
        case .literal(let value):
            return value
            
        case .tags(let format, let tags, let separator):
            let value = tags.compactMap( { allTags?[$0] }).joined(separator: separator)
            return String.format(format, value: value)

        case .extra(let format, let extra, let separator):
            let value = extra.compactMap( {
                guard let value = allExtra?[$0] else {
                    return nil
                }
                
                if let value = value as? String {
                    return value
                }
                
                return String(describing: value)
                
            }).joined(separator: separator)
            
            return String.format(format, value: value)

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
            
        case .userData(let format, let keys, let separator):
            let value = keys.compactMap( { scope.user?.data?[$0] as? String }).joined(separator: separator)
            return String.format(format, value: value)
            
        case .fingerprint:
            return fingerprint ?? scope.fingerprint
            
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
    
    public func format(event: Event) -> String? {
        callback(event)
    }
    
}
