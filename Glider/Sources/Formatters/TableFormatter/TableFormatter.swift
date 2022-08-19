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

/// `TableFormatter` is used to format log messages for console display
/// by presenting data with an ASCII table.
/// This is useful when you need to print complex data using tables rendered via console.
public class TableFormatter: EventMessageFormatter {
    
    // MARK: - Public Properties
    
    /// Fields used to format the message part of the log.
    public var messageFields: [FieldsFormatter.Field] {
        set {
            self.messageFormatter.fields = newValue
        }
        get {
            self.messageFormatter.fields
        }
    }
    
    /// Separator used to compose the message and table fields.
    /// By default is set to `\n`.
    public var separator = "\n"
    
    /// Fields used to format the table's data.
    public var tableFields: [FieldsFormatter.Field]
    
    /// Column titles for table.
    public var columnHeaderTitles = (info: "ID", values: "VALUE")
    
    /// Maximum size of each column.
    public var maxColumnWidths = (info: 40, values: 100)
    
    /// How array and dictionaries (like `tags` and `extra` are encoded).
    /// The default's value is `queryString` but it may change depending
    /// by the formatter.
    public var structureFormatStyle: FieldsFormatter.StructureFormatStyle = .queryString
    
    /// When formatting table keys if values are `nil` the row is not printed.
    /// Set it to `true` to allows `nil` values to be present.
    ///
    /// By default is set to `false`.
    public var includeNilKeys: Bool = false
    
    // MARK: - Private Properties
    
    /// Formatter used to format the message part of the log.
    private var messageFormatter: FieldsFormatter
    
    // MARK: - Initialization
    
    /// Initialize a new table formatter.
    ///
    /// - Parameters:
    ///   - messageFields: fields to show in the first textual message outside the table.
    ///   - tableFields: table contents.
    public init(messageFields: [FieldsFormatter.Field],
                tableFields: [FieldsFormatter.Field]) {
        self.tableFields = tableFields
        self.messageFormatter = FieldsFormatter(fields: messageFields)
    }
    
    // MARK: - Compliance
    
    open func format(event: Event) -> SerializableData? {
        var message = messageFormatter.format(event: event)?.asString() ?? ""
        
        if let table = formatTable(forEvent: event) {
            message += separator + table.stringValue
        }

        return message
    }
    
    /// Default formatter `TableFormatter`.
    /// - Returns: `TableFormatter`
    open class func `default`() -> TableFormatter {
        TableFormatter(
            messageFields: [
                .timestamp(style: .iso8601),
                .delimiter(style: .spacedPipe),
                .message()
            ],
            tableFields: [
                .subsystem(),
                .level(style: .simple),
                .callSite()
            ]
        )
    }
    
    // MARK: - Private Functions
    
    /// Create the table with values.
    ///
    /// - Parameter event: event target.
    /// - Returns: `ASCIITable`
    open func formatTable(forEvent event: Event) -> ASCIITable? {
        let rows = valuesForEvent(event: event)

        guard !tableFields.isEmpty, !rows.isEmpty else {
            return nil
        }
        
        let columnIdentifier = ASCIITable.Column { col in
            col.footer = .init({ footer in
                footer.border = .boxDraw.heavyHorizontal
            })
            col.header = .init(title: self.columnHeaderTitles.info, { header in
                header.fillCharacter = " "
                header.verticalPadding = .init({ padding in
                    padding.top = 0
                    padding.bottom = 0
                })
            })
            col.verticalAlignment = .top
            col.maxWidth = self.maxColumnWidths.info
            col.horizontalAlignment = .leading
        }
        
        
        let columnValues = ASCIITable.Column { col in
            col.footer = .init({ footer in
                footer.border = .boxDraw.heavyHorizontal
            })
            col.header = .init(title: self.columnHeaderTitles.values, { header in
                header.fillCharacter = " "
                header.verticalPadding = .init({ padding in
                    padding.top = 0
                    padding.bottom = 0
                })
            })
            col.maxWidth = self.maxColumnWidths.values
            col.horizontalAlignment = .leading
        }
        
        let columns = ASCIITable.Column.configureBorders(in: [columnIdentifier, columnValues], style: .light)
        return ASCIITable(columns: columns, content: rows)
    }
    
    /// Content of the table for event.
    ///
    /// - Parameter event: event.
    /// - Returns: `[String]`
    open func valuesForEvent(event: Event) -> [String] {
        var contents = [String]()
        
        for field in tableFields {
            guard let tableTitle = field.field.tableTitle,
                  let value = event.valueForFormatterField(field) else {
                continue
            }
            
            switch value {
            case let arrayValue as [String]:
                // Split each value in a custom row of the table along with its keys
                guard let keys = field.field.keysToRetrive, keys.count == arrayValue.count else {
                    break
                }
                for index in 0..<keys.count {
                    contents.append(keys[index])
                    contents.append(arrayValue[index].applyFormattingOfField(field)
                        .split(toWidth: self.maxColumnWidths.values))
                }
                
            case let dictionaryValue as [String: Any]:
                // Split each <key,value> in a dictionary in a separate row
                for key in field.field.keysToRetrive ?? Array(dictionaryValue.keys) {
                    let value = dictionaryValue[key]
                    guard let value = value as? SerializableData else {
                        continue
                    }
                    
                    contents.append(key)
                    contents.append(value.asString()?.applyFormattingOfField(field)
                        .split(toWidth: self.maxColumnWidths.values) ?? "")
                }
                
            case let customKeyValue as (key: String, value: String):
                contents.append(customKeyValue.key)
                contents.append(customKeyValue.value.applyFormattingOfField(field)
                    .split(toWidth: self.maxColumnWidths.values))
                
            default:
                // Just report the row with value
                guard let stringifiedValue = structureFormatStyle.stringify(value, forField: field, includeNilKeys: includeNilKeys) else {
                    continue
                }
                
                contents.append(tableTitle)
                contents.append(stringifiedValue.applyFormattingOfField(field)
                    .split(toWidth: self.maxColumnWidths.values))
            }
        }
        
        return contents
    }
    
}

// MARK: - FieldsFormatter.FieldIdentifier

extension FieldsFormatter.FieldIdentifier {
    
    /// Table's ID title.
    internal var tableTitle: String? {
        switch self {
        case .label:            return "Log Label"
        case .icon:             return "ID"
        case .message:          return "Message"
        case .callSite:         return "Call site"
        case .callingThread:    return "Thread"
        case .category:         return "Category"
        case .eventUUID:        return "UUID"
        case .subsystem:        return "Subsystem"
        case .timestamp:        return "Timestamp"
        case .level:            return "Level"
        case .stackFrame:       return "Stack Frame"
        case .processName:      return "Process"
        case .processID:        return "Process ID"
        case .userId:           return "User ID"
        case .userEmail:        return "User Email"
        case .username:         return "User Name"
        case .ipAddress:        return "IP"
        case .userData:         return "User Data"
        case .fingerprint:      return "Fingerprint"
        case .objectMetadata:   return "Obj Metadata"
        case .object:           return "Obj"
        case .delimiter:        return nil
        case .literal(let t):   return t
        case .tags:             return "Tags"
        case .extra:            return "Extra"
        case .custom:           return nil
        case .customValue(let f): return f(nil)?.key
        }
    }
    
    fileprivate var keysToRetrive: [String]? {
        switch self {
        case .userData(let keys): return keys
        case .objectMetadata(let keys): return keys
        case .tags(let keys): return keys
        case .extra(let keys): return keys
        default: return nil
        }
    }
    
}
