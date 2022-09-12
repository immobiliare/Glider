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

/// This formatter is used to print log into terminals or `stdout`/`stderr`.
/// It also support colors and styles where the output supports ANSI escape codes for colors and styles.
/// By default the formatted fields include an ISO8601 timestamp, the level and the message.
open class TerminalFormatter: FieldsFormatter {
    
    // MARK: - Public Properties
    
    /// Colorize the elements of the log based upon the level of the events posted.
    /// This works for all terminals which support base ANSI colors.
    public let colorize: XCodeFormatter.ColorizeMode
    
    /// What kind of tags should be colorized.
    /// By default is set to `level`.
    public let colorizeFields: XCodeFormatter.ColorizeFields
    
    // MARK: - Initialization
    
    /// Initialize a new formatter.
    ///
    /// - Parameters:
    ///   - colorize: colorize the output.
    ///   - colorizeFields: fields to colorize.
    public init(colorize: XCodeFormatter.ColorizeMode = .onlyImportant,
                colorizeFields: XCodeFormatter.ColorizeFields = [.level, .message]) {
        self.colorize = colorize
        self.colorizeFields = colorizeFields
        let fields = TerminalFormatter.defaultFields(colorize: colorize, colorizeFields: colorizeFields)
        
        super.init(fields: fields)
    }
    
    /// Return the default fields of the default `TerminalFormatter` configuration.
    ///
    /// - Parameters:
    ///   - colorize: colorize mode.
    ///   - colorizeFields: colorized fields.
    /// - Returns: `[FieldsFormatter.Field]`
    open class func defaultFields(colorize: XCodeFormatter.ColorizeMode = .onlyImportant,
                                  colorizeFields: XCodeFormatter.ColorizeFields = [.level, .message]) -> [FieldsFormatter.Field] {
        [
            .timestamp(style: .iso8601),
            .literal(" "),
            .level(style: .simple, { levelCfg in
                levelCfg.padding = .right(columns: 4)
                levelCfg.stringFormat = "[%@] "
                if colorizeFields.contains(.level) {
                    levelCfg.onCustomizeForEvent = { event, tField in
                        // change the formatting field based upon the serverity of the log.
                        tField.colors = ANSITerminalStyles.bestColorForEventLevel(event.level, mode: colorize)
                    }
                }
            }),
            .message({ msgConfig in
                if colorizeFields.contains(.message) {
                    msgConfig.onCustomizeForEvent = { event, tField in
                        tField.colors = ANSITerminalStyles.bestColorForEventLevel(event.level, mode: colorize)
                    }
                }
            })
        ].compactMap({ $0 })
    }
    
}

// MARK: - ANSITerminalStyles Extension

fileprivate extension ANSITerminalStyles {
    
    static func bestColorForEventLevel(_ level: Level, mode: XCodeFormatter.ColorizeMode) -> [ANSITerminalStyles]? {
        if mode == .none { return nil }
        
        switch level {
        case .emergency, .alert, .critical, .error:
            return [.fg(.red)]
        case .warning, .notice:
            return [.fg(.magenta)]
        case .info, .debug:
            guard case .all = mode else { return nil }
            return [.fg(.cyan)]
        case .trace:
            guard case .all = mode else { return nil }
            return [.fg(.green)]
        }
    }
    
}
