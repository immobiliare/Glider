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

/// The`XCodeFormatter` is used to print messages directly on XCode debug console.
/// It mimics the typical structure of debug messages and also add colorization
/// to the output.
///
/// While XCode console does not support colorization anymore you can still use an
/// hack to show them. Take a look at `colorize` property for more informations.
open class XCodeFormatter: FieldsFormatter {
    
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
    /// You should therefore download the following custom fonts (based upon FiraCode)
    /// named [ColoredConsole-Bold.ttf](https://raw.githubusercontent.com/jjrscott/ColoredConsole/master/ColoredConsole-Bold.ttf)
    /// and set as the default font for XCode's Console Messages (`Preferences > Themes > Console`).
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
                colorizeFields: ColorizeFields = [.level, .message]) {
        
        self.colorize = colorize
        self.colorizeFields = colorizeFields
        self.showCallSite = showCallSite
        let fields = XCodeFormatter.defaultFields(showCallSite: showCallSite, colorize: colorize, colorizeFields: colorizeFields)
        
        super.init(fields: fields)
    }
    
    /// Return the default fields of the default `TerminalFormatter` configuration.
    ///
    /// - Parameters:
    ///   - colorize: colorize mode.
    ///   - colorizeFields: colorized fields.
    /// - Returns: `[FieldsFormatter.Field]`
    open class func defaultFields(showCallSite: Bool = false,
                                  colorize: ColorizeMode = .onlyImportant,
                                  colorizeFields: ColorizeFields = [.level, .message]) -> [FieldsFormatter.Field] {
        [
            .timestamp(style: .iso8601),
            .literal(" "),
            (showCallSite == false ? nil : .callSite({ callSiteCfg in
                callSiteCfg.stringFormat = "(%@) "
                if colorizeFields.contains(.callSite) {
                    callSiteCfg.onCustomizeForEvent = { event, tField in
                        tField.colors = XCodeConsoleColor.bestColorForEventLevel(event.level, mode: colorize)
                    }
                }
            })),
            .level(style: .simple, { levelCfg in
                levelCfg.padding = .right(columns: 4)
                levelCfg.stringFormat = "[%@] "
                if colorizeFields.contains(.level) {
                    levelCfg.onCustomizeForEvent = { event, tField in
                        // change the formatting field based upon the serverity of the log.
                        tField.colors = XCodeConsoleColor.bestColorForEventLevel(event.level, mode: colorize)
                    }
                }
            }),
            .message({ msgCfg in
                if colorizeFields.contains(.message) {
                    msgCfg.onCustomizeForEvent = { event, tField in
                        tField.colors = XCodeConsoleColor.bestColorForEventLevel(event.level, mode: colorize)
                    }
                }
            })
        ].compactMap({ $0 })
    }
    
    @available(*, unavailable)
    public override init(fields: [FieldsFormatter.Field]) {
        fatalError("Use init(options:) for JSONFormatter")
    }
    
}
