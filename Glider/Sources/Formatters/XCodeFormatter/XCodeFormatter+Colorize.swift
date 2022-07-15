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
        
        /// Apply unicode variant codes to colorize the text.
        /// `ColoredConsole-Bold` fonts must be active in console to see the result.
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
