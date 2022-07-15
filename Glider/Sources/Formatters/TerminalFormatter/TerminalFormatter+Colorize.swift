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

public enum ANSITerminalColors: FieldsFormatterColor {
    case bg(ANSIColor)
    case fg(ANSIColor)
    case style(ANSIStyle)
    
    public func colorize(_ string: String) -> String {
        return string
    }
    
}

public enum ANSIColor {
    case black
    case red
    case green
    case yellow
    case blue
    case magenta
    case cyan
    case white
}

public enum ANSIStyle {
    case reset
    case bold
    case italic
    case underline
    case blink
    case inverse
    case strikethrough
}
