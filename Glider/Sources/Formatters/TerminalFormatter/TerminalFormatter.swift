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

public class TerminalFormatter: FieldsFormatter {
    
    // MARK: - Public Properties
    
    public let colorize: XCodeFormatter.ColorizeMode
    
    /// What kind of tags should be colorized.
    /// By default is set to `level`.
    public let colorizeFields: XCodeFormatter.ColorizeFields
    
    // MARK: - Initialization
    
    public init(colorize: XCodeFormatter.ColorizeMode = .onlyImportant,
                colorizeFields: XCodeFormatter.ColorizeFields = [.level, .message]) {
        let fields: [FieldsFormatter.Field] = [
            .timestamp(style: .iso8601),
            .literal(" "),
            .level(style: .simple, {
                $0.padding = .right(columns: 4)
                $0.stringFormat = "[%@] "
                if colorizeFields.contains(.level) {
                    $0.onCustomizeForEvent = { event, tField in
                        // change the formatting field based upon the serverity of the log.
                        tField.color = ANSITerminalColors.bestColorForEventLevel(event.level, mode: colorize)
                    }
                }
            }),
            .message({
                if colorizeFields.contains(.message) {
                    $0.onCustomizeForEvent = { event, tField in
                        tField.color = ANSITerminalColors.bestColorForEventLevel(event.level, mode: colorize)
                    }
                }
            })
        ].compactMap({ $0 })
        
        self.colorize = colorize
        self.colorizeFields = colorizeFields
        
        super.init(fields: fields)
    }
    
}

fileprivate extension ANSITerminalColors {
    
    static func bestColorForEventLevel(_ level: Level, mode: XCodeFormatter.ColorizeMode) -> ANSITerminalColors? {
        if mode == .none { return nil }
        
        switch level {
        case .emergency, .alert, .critical, .error:
            return .fg(.red)
        case .warning, .notice:
            return .fg(.magenta)
        case .info, .debug:
            guard case .all = mode else { return nil }
            return .fg(.cyan)
        case .trace:
            guard case .all = mode else { return nil }
            return .fg(.green)
        }
    }
    
}
