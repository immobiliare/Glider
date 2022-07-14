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

public class XCodeFormatter: FieldsFormatter {
    
    // MARK: - Public Properties
    
    /// If `true`, the source file and line indicating
    /// the call site of the log request will be added to formatted log messages.
    public let showCallSite: Bool
    
    /// Colorize the elements of the log based upon the level of the events posted.
    ///
    /// By default both the `message` and `level` are colorized automatically.
    /// If you want to colorize other elements you must provide a custom `FieldFormatter.Field`
    /// array and set the color of each token.
    ///
    /// IMPORTANT:
    /// Colorization of the console is no more supported since XCode 8. In order to
    /// works this method uses the technique of the fonts color variants.
    /// You should therefore download the following custom fonts (based upon FiraCode):
    /// <https://raw.githubusercontent.com/jjrscott/ColoredConsole/master/ColoredConsole-Bold.ttf>
    /// and set as the default font for XCode's Console Messages (Preferences > Themes > Console).
    public let colorize: ColorizeMode
    
    /// What kind of tags should be colorized.
    /// By default is set to `level`.
    public let colorizeFields: ColorizeFields
    
    // MARK: - Initialization
    
    /// Initialize a new formatter which is ideal for use within XCode.
    /// This format is not well-suited for parsing.
    ///
    /// - Parameters:
    ///   - showCallSite: If `true`, the source file and line indicating the call site of the log request
    ///                   will be added to formatted log messages.
    ///   - colorize: used to colorize the messages inside the xcode console
    ///               (see the notice on `colorize` property to properly
    ///
    ///   setup the environment to show colors!
    public init(showCallSite: Bool = false,
                colorize: ColorizeMode = .onlyImportant,
                colorizeFields: ColorizeFields = [.level]) {
        let fields: [FieldsFormatter.Field] = [
            .timestamp(style: .iso8601),
            .literal(" "),
            .level(style: .short, {
                $0.padding = .right(columns: 4)
                
                if colorizeFields.contains(.level) {
                    $0.onCustomizeForEvent = { event, tField in
                        // change the formatting field based upon the serverity of the log.
                        tField.color = XCodeConsoleColor.bestColorForEventLevel(event.level, mode: colorize)
                    }
                }
            }),
            (showCallSite == false ? nil : .callSite({
                $0.stringFormat = " (%@) "
                
                if colorizeFields.contains(.callSite) {
                    $0.onCustomizeForEvent = { event, tField in
                        tField.color = XCodeConsoleColor.bestColorForEventLevel(event.level, mode: colorize)
                    }
                }
            })),
            .literal(": "),
            .message({
                if colorizeFields.contains(.message) {
                    $0.onCustomizeForEvent = { event, tField in
                        tField.color = XCodeConsoleColor.bestColorForEventLevel(event.level, mode: colorize)
                    }
                }
            })
        ].compactMap({ $0 })
        
        self.colorize = colorize
        self.colorizeFields = colorizeFields
        self.showCallSite = showCallSite
        
        super.init(fields: fields)
    }
    
    @available(*, unavailable)
    public override init(fields: [FieldsFormatter.Field]) {
        fatalError("Use init(options:) for JSONFormatter")
    }
    
}

// MARK: - XCodeLogFormatter.LogElements

extension XCodeFormatter {
    
    // MARK: - ColorizeMode
    
    /// Rules to colorize a message.
    /// - `none` does not apply colorization of the message.
    /// - `onlyImportant`: only important levels (warning, critical, error, emergency, notice) are colored.
    /// - `all`: all messages are colored based upon their level.
    public enum ColorizeMode {
        case none
        case onlyImportant
        case all
    }
    
    /// What kind of fields should be colorized.
    public struct ColorizeFields: OptionSet {
        public let rawValue: Int
        
        public static let callSite = ColorizeFields(rawValue: 1 << 0)
        public static let message = ColorizeFields(rawValue: 1 << 1)
        public static let level = ColorizeFields(rawValue: 2 << 2)
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    // MARK: - XCodeConsoleColor
    
    /// Allows to colorize the text inside the XCode console which by default
    /// does not support this option since XCode 8.
    /// It uses the concept of colored variants of fonts well described in this
    /// repository <https://github.com/jjrscott/ColoredConsole>.
    /// Just download the font from here:
    /// <https://raw.githubusercontent.com/jjrscott/ColoredConsole/master/ColoredConsole-Bold.ttf>
    /// And set it as the font for Console fonts inside the settings panel of xcode.
    public enum XCodeConsoleColor: FieldsFormatterColor {
        case reset
        case red
        case green
        case ochre
        case cyan
        case violet
        
        /// Apply escape codes to colorize the text.
        ///
        /// - Parameter string: string message.
        /// - Returns: `String`
        public func colorize(_ string: String) -> String {
            switch self {
            case .reset:
                return Array(string).map({"\($0)\u{fe05}"}).joined()
            case .red:
                return Array(string).map({"\($0)\u{fe06}"}).joined()
            case .green:
                return Array(string).map({"\($0)\u{fe07}"}).joined()
            case .ochre:
                return Array(string).map({"\($0)\u{fe08}"}).joined()
            case .cyan:
                return Array(string).map({"\($0)\u{fe09}"}).joined()
            case .violet:
                return Array(string).map({"\($0)\u{fe0A}"}).joined()
            }
        }
        
        /// Return the best color to use to colorize an event details.
        ///
        /// - Parameters:
        ///   - level: level of the event.
        ///   - mode: colorization mode to follow.
        /// - Returns: `XCodeConsoleColor?`
        internal static func bestColorForEventLevel(_ level: Level, mode: ColorizeMode) -> XCodeConsoleColor? {
            if mode == .none { return nil }
            
            switch level {
            case .emergency, .alert, .critical, .error:
                return .red
            case .warning, .notice:
                return .ochre
            case .info, .debug:
                guard case .all = mode else { return nil }
                return .cyan
            case .trace:
                guard case .all = mode else { return nil }
                return .green
            }
        }
        
    }
    
}
