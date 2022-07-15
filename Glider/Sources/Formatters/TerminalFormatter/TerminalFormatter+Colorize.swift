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

/// Styles you can apply to a text showed inside the terminal console which support ANSI styles.
/// - `bg`: background color.
/// - `fg`: foreground text color.
/// - `style`: styles to apply.
public enum ANSITerminalStyles: FieldsFormatterColor {
    case bg(Color)
    case fg(Color)
    case style(Style)
    
    // MARK: - Public Functions
    
    public func colorize(_ string: String) -> String {
        switch self {
        case .fg(let color):
            return string.textColor(color)
        case .bg(let color):
            return string.backgroundColor(color)
        case .style(let style):
            return string.style(style)
        }
    }
    
    // MARK: - Internal Properties
    
    /// ANSI escape code.
    internal var escapeCode: String {
        var code = Style.reset.code
        
        switch self {
        case .fg(let color):
            code = color.code
        case .bg(let color):
            code = color.code + 10
        case .style(let style):
            code = style.code
        }
        
        return "\u{001B}[\(code)m"
    }
    
}

// MARK: - Colors

extension ANSITerminalStyles {
    
    /// Defines the color you can apply both as background or foreground.
    public enum Color {
        case black
        case red
        case green
        case yellow
        case blue
        case magenta
        case cyan
        case white
        
        // MARK: - Internal Properties
        
        internal var code: Int {
            switch self {
            case .black: return 30
            case .red: return 31
            case .green: return 32
            case .yellow: return 33
            case .blue: return 34
            case .magenta: return 35
            case .cyan: return 36
            case .white: return 37
            }
        }
        
    }
    
}

// MARK: - Style

extension ANSITerminalStyles {
    
    /// Defines the style of the text you can apply.
    public enum Style {
        case reset
        case bold
        case italic
        case underline
        case blink
        case inverse
        case strikethrough
        
        // MARK: - Internal Properties
        
        internal var code: Int {
            switch self {
            case .reset: return 0
            case .bold: return 1
            case .italic: return 3
            case .underline: return 4
            case .blink: return 5
            case .inverse: return 7
            case .strikethrough: return 9
            }
        }
    }
    
}

// MARK: - String Internal Extension

internal extension String {
    
    func ansi(_ ansi: ANSITerminalStyles) -> String {
        let reset = ANSITerminalStyles.style(.reset).escapeCode
        return "\(ansi.escapeCode)\(self)\(reset)"
    }

    func textColor(_ color: ANSITerminalStyles.Color) -> String {
        return self.ansi(.fg(color))
    }

    func backgroundColor(_ color: ANSITerminalStyles.Color) -> String {
        return self.ansi(.bg(color))
    }

    func style(_ style: ANSITerminalStyles.Style) -> String {
        return self.ansi(.style(style))
    }
    
}
