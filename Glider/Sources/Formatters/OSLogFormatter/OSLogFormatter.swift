//
//  Glider
//  Fast, Lightweight yet powerful logging system for Swift.
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Authors:
//   - Daniele Margutti <hello@danielemargutti.com>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

/// The`OSLogFormatter` is used to print messages directly on XCode debug console with OSLog.
open class OSLogFormatter: FieldsFormatter {
    
    // MARK: - Initialization
    
    public init() {
        super.init(fields: Self.defaultFields())
    }
    
    /// Return the default fields of the default `TerminalFormatter` configuration.
    ///
    /// - Parameters:
    ///   - colorize: colorize mode.
    ///   - colorizeFields: colorized fields.
    /// - Returns: `[FieldsFormatter.Field]`
    open class func defaultFields() -> [FieldsFormatter.Field] {
        [
            .timestamp(style: .iso8601),
            .literal(" "),
            .message()
        ].compactMap({ $0 })
    }
    
    @available(*, unavailable)
    public override init(fields: [FieldsFormatter.Field]) {
        fatalError("Use init(options:) for JSONFormatter")
    }
    
}
