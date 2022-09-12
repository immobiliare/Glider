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

//  The following code was inspired by <https://github.com/juri/TableDraw>.

import Foundation

// MARK: - ASCIITable

/// Represent an ASCII Table printable to terminals and consoles.
public struct ASCIITable {
    
    // MARK: - Public Properties
    
    /// Columns to set.
    public var columns: [Column]
    
    /// Content of the rows.
    public var content: [TerminalDisplay]

    // MARK: - Initialize
    
    /// Initialize a new table.
    ///
    /// - Parameters:
    ///   - columns: columns to set.
    ///   - content: content to set.
    public init(columns: [Column], content: [TerminalDisplay]) {
        self.columns = columns
        self.content = content
    }
    
}

// MARK: - ASCIITable.Column

extension ASCIITable {
    
    public struct Column {
        
        // MARK: - Public Properties
        
        public var fillCharacter: Character = " "
        public var footer: Footer?
        public var header: Header?
        public var horizontalAlignment: HorizontalAlignment = .leading
        public var leadingMargin: String = ""
        public var minWidth: Int = 0
        public var trailingMargin: String = ""
        public var verticalAlignment: VerticalAlignment = .middle
        public var verticalPadding: VerticalPadding = .zero
        public var maxWidth: Int?
        
        // MARK: - Initialization
        
        public init(_ builder: ((inout Column) -> Void)? = nil) {
            builder?(&self)
        }
        
        var visibleFooter: Bool {
            self.footer.map(\.visible) ?? false
        }
        
    }
    
}

// MARK: - Column Header

extension ASCIITable.Column {
    
    public struct Header {
        public var bottomBorder: Character?
        public var corners: Corners = .default
        public var fillCharacter: Character = " "
        public var horizontalAlignment: HorizontalAlignment = .leading
        public var leadingMargin: String = ""
        public var minHeight: Int = 0
        public var title: String
        public var topBorder: Character?
        public var trailingMargin: String = ""
        public var verticalAlignment: VerticalAlignment = .top
        public var verticalPadding: VerticalPadding = .zero
        
        public init(title: String, _ builder: ((inout Header) -> Void)? = nil) {
            self.title = title
            builder?(&self)
        }
        
        internal var decorationHeight: Int {
            (self.bottomBorder != nil ? 1 : 0) + (self.topBorder != nil ? 1 : 0) + self.verticalPadding.total
        }
        
    }
    
}

// MARK: - Column Footer

extension ASCIITable.Column {
    
    public struct Footer {
        public var border: Character?
        public var leadingCorner: Character?
        public var trailingCorner: Character?
        
        public init(_ builder: ((inout Footer) -> Void)? = nil) {
            builder?(&self)
        }
        
        var visible: Bool {
            self.border != nil || self.leadingCorner != nil || self.trailingCorner != nil
        }

        var cornerLength: Int {
            (self.leadingCorner != nil ? 1 : 0) + (self.trailingCorner != nil ? 1 : 0)
        }
        
    }
}

// MARK: - Column Corners

extension ASCIITable.Column {
    
    public struct Corners {
        public var topLeading: Character?
        public var topTrailing: Character?
        public var bottomTrailing: Character?
        public var bottomLeading: Character?
        
        public static let `default`: Corners = .init()
        
        public init(_ builder: ((inout Corners) -> Void)? = nil) {
            builder?(&self)
        }
        
    }
    
}

// MARK: - Horizontal Alignment

extension ASCIITable.Column {
    
    public enum HorizontalAlignment {
        case leading
        case center
        case trailing
        
        func apply(text: [Substring], width: Int, fillCharacter: Character) -> [String] {
            text
                .map { line -> String in
                    let length = line.count
                    guard length < width else { return String(line) }
                    let pad = width - length
                    switch self {
                    case .leading:
                        return line + String(repeating: fillCharacter, count: pad)
                    case .center:
                        let leftPad = Int(Double(pad) / 2.0)
                        let rightPad = leftPad * 2 < pad ? leftPad + 1 : leftPad
                        let left = String(repeating: fillCharacter, count: leftPad)
                        let right = String(repeating: fillCharacter, count: rightPad)
                        return "\(left)\(line)\(right)"
                    case .trailing:
                        return String(repeating: fillCharacter, count: pad) + line
                    }
                }
        }
    }
    
}

// MARK: - Vertical Alignment

extension ASCIITable.Column {
    
    public enum VerticalAlignment {
        case top
        case middle
        case bottom
        
        func apply(text: [Substring], height: Int) -> [Substring] {
            guard text.count < height else { return text }
            let emptySub = ""[...]
            let pad = height - text.count
            switch self {
            case .top:
                return text + [Substring](repeating: emptySub, count: pad)
            case .middle:
                let topPad = Int(Double(pad) / 2.0)
                let bottomPad = topPad * 2 < pad ? topPad + 1 : topPad
                return (
                    [Substring](repeating: emptySub, count: topPad) +
                        text +
                        [Substring](repeating: emptySub, count: bottomPad)
                )
            case .bottom:
                return [Substring](repeating: emptySub, count: pad) + text
            }
        }
    }
    
    public struct VerticalPadding: Equatable {
        public var top: Int = 0
        public var bottom: Int = 0

        public static let zero = VerticalPadding()

        public init(_ builder: ((inout VerticalPadding) -> Void)? = nil) {
            builder?(&self)
        }

        public var total: Int {
            top + bottom
        }

        func apply(lines: [Substring]) -> [Substring] {
            guard self != Self.zero else { return lines }
            return (
                [Substring](repeating: ""[...], count: self.top) +
                    lines +
                    [Substring](repeating: ""[...], count: self.bottom)
            )
        }
        
    }
    
}

extension Character {
    public enum BoxDrawn {
        /// Unicode box drawing character `─`
        public static let lightHorizontal: Character = "─"
        /// Unicode box drawing character `━`
        public static let heavyHorizontal: Character = "━"
        /// Unicode box drawing character `│`
        public static let lightVertical: Character = "│"
        /// Unicode box drawing character `┃`
        public static let heavyVertical: Character = "┃"
        /// Unicode box drawing character `┄`
        public static let lightTripleDashHorizontal: Character = "┄"
        /// Unicode box drawing character `┅`
        public static let heavyTripleDashHorizontal: Character = "┅"
        /// Unicode box drawing character `┆`
        public static let lightTripleDashVertical: Character = "┆"
        /// Unicode box drawing character `┇`
        public static let heavyTripleDashVertical: Character = "┇"
        /// Unicode box drawing character `┈`
        public static let lightQuadrupleDashHorizontal: Character = "┈"
        /// Unicode box drawing character `┉`
        public static let heavyQuadrupleDashHorizontal: Character = "┉"
        /// Unicode box drawing character `┊`
        public static let lightQuadrupleDashVertical: Character = "┊"
        /// Unicode box drawing character `┋`
        public static let heavyQuadrupleDashVertical: Character = "┋"
        /// Unicode box drawing character `┌`
        public static let lightDownAndRight: Character = "┌"
        /// Unicode box drawing character `┍`
        public static let downLightAndRightHeavy: Character = "┍"
        /// Unicode box drawing character `┎`
        public static let downHeavyAndRightLight: Character = "┎"
        /// Unicode box drawing character `┏`
        public static let heavyDownAndRight: Character = "┏"
        /// Unicode box drawing character `┐`
        public static let lightDownAndLeft: Character = "┐"
        /// Unicode box drawing character `┑`
        public static let downLightAndLeftHeavy: Character = "┑"
        /// Unicode box drawing character `┒`
        public static let downHeavyAndLeftLight: Character = "┒"
        /// Unicode box drawing character `┓`
        public static let heavyDownAndLeft: Character = "┓"
        /// Unicode box drawing character `└`
        public static let lightUpAndRight: Character = "└"
        /// Unicode box drawing character `┕`
        public static let upLightAndRightHeavy: Character = "┕"
        /// Unicode box drawing character `┖`
        public static let upHeavyAndRightLight: Character = "┖"
        /// Unicode box drawing character `┗`
        public static let heavyUpAndRight: Character = "┗"
        /// Unicode box drawing character `┘`
        public static let lightUpAndLeft: Character = "┘"
        /// Unicode box drawing character `┙`
        public static let upLightAndLeftHeavy: Character = "┙"
        /// Unicode box drawing character `┚`
        public static let upHeavyAndLeftLight: Character = "┚"
        /// Unicode box drawing character `┛`
        public static let heavyUpAndLeft: Character = "┛"
        /// Unicode box drawing character `├`
        public static let lightVerticalAndRight: Character = "├"
        /// Unicode box drawing character `┝`
        public static let verticalLightAndRightHeavy: Character = "┝"
        /// Unicode box drawing character `┞`
        public static let upHeavyAndRightDownLight: Character = "┞"
        /// Unicode box drawing character `┟`
        public static let downHeavyAndRightUpLight: Character = "┟"
        /// Unicode box drawing character `┠`
        public static let verticalHeavyAndRightLight: Character = "┠"
        /// Unicode box drawing character `┡`
        public static let downLightAndRightUpHeavy: Character = "┡"
        /// Unicode box drawing character `┢`
        public static let upLightAndRightDownHeavy: Character = "┢"
        /// Unicode box drawing character `┣`
        public static let heavyVerticalAndRight: Character = "┣"
        /// Unicode box drawing character `┤`
        public static let lightVerticalAndLeft: Character = "┤"
        /// Unicode box drawing character `┥`
        public static let verticalLightAndLeftHeavy: Character = "┥"
        /// Unicode box drawing character `┦`
        public static let upHeavyAndLeftDownLight: Character = "┦"
        /// Unicode box drawing character `┧`
        public static let downHeavyAndLeftUpLight: Character = "┧"
        /// Unicode box drawing character `┨`
        public static let verticalHeavyAndLeftLight: Character = "┨"
        /// Unicode box drawing character `┩`
        public static let downLightAndLeftUpHeavy: Character = "┩"
        /// Unicode box drawing character `┪`
        public static let upLightAndLeftDownHeavy: Character = "┪"
        /// Unicode box drawing character `┫`
        public static let heavyVerticalAndLeft: Character = "┫"
        /// Unicode box drawing character `┬`
        public static let lightDownAndHorizontal: Character = "┬"
        /// Unicode box drawing character `┭`
        public static let leftHeavyAndRightDownLight: Character = "┭"
        /// Unicode box drawing character `┮`
        public static let rightHeavyAndLeftDownLight: Character = "┮"
        /// Unicode box drawing character `┯`
        public static let downLightAndHorizontalHeavy: Character = "┯"
        /// Unicode box drawing character `┰`
        public static let downHeavyAndHorizontalLight: Character = "┰"
        /// Unicode box drawing character `┱`
        public static let rightLightAndLeftDownHeavy: Character = "┱"
        /// Unicode box drawing character `┲`
        public static let leftLightAndRightDownHeavy: Character = "┲"
        /// Unicode box drawing character `┳`
        public static let heavyDownAndHorizontal: Character = "┳"
        /// Unicode box drawing character `┴`
        public static let lightUpAndHorizontal: Character = "┴"
        /// Unicode box drawing character `┵`
        public static let leftHeavyAndRightUpLight: Character = "┵"
        /// Unicode box drawing character `┶`
        public static let rightHeavyAndLeftUpLight: Character = "┶"
        /// Unicode box drawing character `┷`
        public static let upLightAndHorizontalHeavy: Character = "┷"
        /// Unicode box drawing character `┸`
        public static let upHeavyAndHorizontalLight: Character = "┸"
        /// Unicode box drawing character `┹`
        public static let rightLightAndLeftUpHeavy: Character = "┹"
        /// Unicode box drawing character `┺`
        public static let leftLightAndRightUpHeavy: Character = "┺"
        /// Unicode box drawing character `┻`
        public static let heavyUpAndHorizontal: Character = "┻"
        /// Unicode box drawing character `┼`
        public static let lightVerticalAndHorizontal: Character = "┼"
        /// Unicode box drawing character `┽`
        public static let leftHeavyAndRightVerticalLight: Character = "┽"
        /// Unicode box drawing character `┾`
        public static let rightHeavyAndLeftVerticalLight: Character = "┾"
        /// Unicode box drawing character `┿`
        public static let verticalLightAndHorizontalHeavy: Character = "┿"
        /// Unicode box drawing character `╀`
        public static let upHeavyAndDownHorizontalLight: Character = "╀"
        /// Unicode box drawing character `╁`
        public static let downHeavyAndUpHorizontalLight: Character = "╁"
        /// Unicode box drawing character `╂`
        public static let verticalHeavyAndHorizontalLight: Character = "╂"
        /// Unicode box drawing character `╃`
        public static let leftUpHeavyAndRightDownLight: Character = "╃"
        /// Unicode box drawing character `╄`
        public static let rightUpHeavyAndLeftDownLight: Character = "╄"
        /// Unicode box drawing character `╅`
        public static let leftDownHeavyAndRightUpLight: Character = "╅"
        /// Unicode box drawing character `╆`
        public static let rightDownHeavyAndLeftUpLight: Character = "╆"
        /// Unicode box drawing character `╇`
        public static let downLightAndUpHorizontalHeavy: Character = "╇"
        /// Unicode box drawing character `╈`
        public static let upLightAndDownHorizontalHeavy: Character = "╈"
        /// Unicode box drawing character `╉`
        public static let rightLightAndLeftVerticalHeavy: Character = "╉"
        /// Unicode box drawing character `╊`
        public static let leftLightAndRightVerticalHeavy: Character = "╊"
        /// Unicode box drawing character `╋`
        public static let heavyVerticalAndHorizontal: Character = "╋"
        /// Unicode box drawing character `╌`
        public static let lightDoubleDashHorizontal: Character = "╌"
        /// Unicode box drawing character `╍`
        public static let heavyDoubleDashHorizontal: Character = "╍"
        /// Unicode box drawing character `╎`
        public static let lightDoubleDashVertical: Character = "╎"
        /// Unicode box drawing character `╏`
        public static let heavyDoubleDashVertical: Character = "╏"
        /// Unicode box drawing character `═`
        public static let doubleHorizontal: Character = "═"
        /// Unicode box drawing character `║`
        public static let doubleVertical: Character = "║"
        /// Unicode box drawing character `╒`
        public static let downSingleAndRightDouble: Character = "╒"
        /// Unicode box drawing character `╓`
        public static let downDoubleAndRightSingle: Character = "╓"
        /// Unicode box drawing character `╔`
        public static let doubleDownAndRight: Character = "╔"
        /// Unicode box drawing character `╕`
        public static let downSingleAndLeftDouble: Character = "╕"
        /// Unicode box drawing character `╖`
        public static let downDoubleAndLeftSingle: Character = "╖"
        /// Unicode box drawing character `╗`
        public static let doubleDownAndLeft: Character = "╗"
        /// Unicode box drawing character `╘`
        public static let upSingleAndRightDouble: Character = "╘"
        /// Unicode box drawing character `╙`
        public static let upDoubleAndRightSingle: Character = "╙"
        /// Unicode box drawing character `╚`
        public static let doubleUpAndRight: Character = "╚"
        /// Unicode box drawing character `╛`
        public static let upSingleAndLeftDouble: Character = "╛"
        /// Unicode box drawing character `╜`
        public static let upDoubleAndLeftSingle: Character = "╜"
        /// Unicode box drawing character `╝`
        public static let doubleUpAndLeft: Character = "╝"
        /// Unicode box drawing character `╞`
        public static let verticalSingleAndRightDouble: Character = "╞"
        /// Unicode box drawing character `╟`
        public static let verticalDoubleAndRightSingle: Character = "╟"
        /// Unicode box drawing character `╠`
        public static let doubleVerticalAndRight: Character = "╠"
        /// Unicode box drawing character `╡`
        public static let verticalSingleAndLeftDouble: Character = "╡"
        /// Unicode box drawing character `╢`
        public static let verticalDoubleAndLeftSingle: Character = "╢"
        /// Unicode box drawing character `╣`
        public static let doubleVerticalAndLeft: Character = "╣"
        /// Unicode box drawing character `╤`
        public static let downSingleAndHorizontalDouble: Character = "╤"
        /// Unicode box drawing character `╥`
        public static let downDoubleAndHorizontalSingle: Character = "╥"
        /// Unicode box drawing character `╦`
        public static let doubleDownAndHorizontal: Character = "╦"
        /// Unicode box drawing character `╧`
        public static let upSingleAndHorizontalDouble: Character = "╧"
        /// Unicode box drawing character `╨`
        public static let upDoubleAndHorizontalSingle: Character = "╨"
        /// Unicode box drawing character `╩`
        public static let doubleUpAndHorizontal: Character = "╩"
        /// Unicode box drawing character `╪`
        public static let verticalSingleAndHorizontalDouble: Character = "╪"
        /// Unicode box drawing character `╫`
        public static let verticalDoubleAndHorizontalSingle: Character = "╫"
        /// Unicode box drawing character `╬`
        public static let doubleVerticalAndHorizontal: Character = "╬"
        /// Unicode box drawing character `╭`
        public static let lightArcDownAndRight: Character = "╭"
        /// Unicode box drawing character `╮`
        public static let lightArcDownAndLeft: Character = "╮"
        /// Unicode box drawing character `╯`
        public static let lightArcUpAndLeft: Character = "╯"
        /// Unicode box drawing character `╰`
        public static let lightArcUpAndRight: Character = "╰"
        /// Unicode box drawing character `╱`
        public static let lightDiagonalUpperRightToLowerLeft: Character = "╱"
        /// Unicode box drawing character `╲`
        public static let lightDiagonalUpperLeftToLowerRight: Character = "╲"
        /// Unicode box drawing character `╳`
        public static let lightDiagonalCross: Character = "╳"
        /// Unicode box drawing character `╴`
        public static let lightLeft: Character = "╴"
        /// Unicode box drawing character `╵`
        public static let lightUp: Character = "╵"
        /// Unicode box drawing character `╶`
        public static let lightRight: Character = "╶"
        /// Unicode box drawing character `╷`
        public static let lightDown: Character = "╷"
        /// Unicode box drawing character `╸`
        public static let heavyLeft: Character = "╸"
        /// Unicode box drawing character `╹`
        public static let heavyUp: Character = "╹"
        /// Unicode box drawing character `╺`
        public static let heavyRight: Character = "╺"
        /// Unicode box drawing character `╻`
        public static let heavyDown: Character = "╻"
        /// Unicode box drawing character `╼`
        public static let lightLeftAndHeavyRight: Character = "╼"
        /// Unicode box drawing character `╽`
        public static let lightUpAndHeavyDown: Character = "╽"
        /// Unicode box drawing character `╾`
        public static let heavyLeftAndLightRight: Character = "╾"
        /// Unicode box drawing character `╿`
        public static let heavyUpAndLightDown: Character = "╿"
    }
}

// MARK: - Protocols

public protocol TerminalDisplay {
    var stringValue: String { get }
}

extension String: TerminalDisplay {
    public var stringValue: String { self }
}

extension TerminalDisplay where Self: CustomStringConvertible {
    public var stringValue: String {
        String(describing: self)
    }
}
