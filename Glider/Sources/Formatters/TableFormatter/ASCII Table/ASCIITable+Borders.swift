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

extension ASCIITable.Column {
    
    // MARK: - Public Functions
    
    /// Configure borders of the table.
    ///
    /// - Parameters:
    ///   - columns: columns to set.
    ///   - style: style to set.
    ///   - horizontalMargin: margin in horizontal.
    /// - Returns: [Table.Column]
    public static func configureBorders(in columns: [ASCIITable.Column],
                                        style: ASCIITable.BorderStyle,
                                        horizontalMargin: String = " ") -> [ASCIITable.Column] {
        var cols = columns
        self.configureBorders(in: &cols, uniformStyle: style, horizontalMargin: horizontalMargin)
        return cols
    }
    
    // MARK: - Private Functions
    
    private static func configureBorders(in columns: inout [ASCIITable.Column],
                                         uniformStyle style: ASCIITable.BorderStyle,
                                         horizontalMargin: String = " ") {
        guard !columns.isEmpty else { return }
        let multipleColumns = columns.count > 1
        columns[0].leadingMargin = "\(style.vertical)\(horizontalMargin)"
        columns[0].trailingMargin = "\(horizontalMargin)\(style.vertical)"
        columns[0].footer = .init({
            $0.border = style.horizontal
            $0.leadingCorner = style.upAndRight
            $0.trailingCorner = (multipleColumns ? style.upAndHorizontal : style.upAndLeft)
        })
        columns[0].header?.bottomBorder = style.horizontal
        columns[0].header?.topBorder = style.horizontal
        columns[0].header?.leadingMargin = "\(style.vertical)\(horizontalMargin)"
        columns[0].header?.trailingMargin = "\(horizontalMargin)\(style.vertical)"
        columns[0].header?.corners = .init({
            $0.topLeading = style.downAndRight
            $0.topTrailing = multipleColumns ? style.downAndHorizontal : style.downAndLeft
            $0.bottomTrailing = multipleColumns ? style.verticalAndHorizontal : style.verticalAndLeft
            $0.bottomLeading = style.verticalAndRight
        })

        let lastIndex = columns.endIndex.advanced(by: -1)
        guard lastIndex > 0 else { return }

        for index in 1 ..< lastIndex {
            columns[index].leadingMargin = horizontalMargin
            columns[index].trailingMargin = "\(horizontalMargin)\(style.vertical)"
            columns[index].footer = .init({
                $0.border = style.horizontal
                $0.leadingCorner = nil
                $0.trailingCorner = style.upAndHorizontal
            })
            columns[index].header?.bottomBorder = style.horizontal
            columns[index].header?.topBorder = style.horizontal
            columns[index].header?.leadingMargin = horizontalMargin
            columns[index].header?.trailingMargin = "\(horizontalMargin)\(style.vertical)"
            columns[index].header?.corners = .init({
                $0.topLeading = style.horizontal
                $0.topTrailing = style.downAndHorizontal
                $0.bottomTrailing = style.verticalAndHorizontal
                $0.bottomLeading = style.horizontal
            })
        }

        columns[lastIndex].leadingMargin = horizontalMargin
        columns[lastIndex].trailingMargin = "\(horizontalMargin)\(style.vertical)"
        columns[lastIndex].footer = .init({
            $0.border = style.horizontal
            $0.leadingCorner = style.horizontal
            $0.trailingCorner =  style.upAndLeft
        })
        columns[lastIndex].header?.bottomBorder = style.horizontal
        columns[lastIndex].header?.topBorder = style.horizontal
        columns[lastIndex].header?.leadingMargin = horizontalMargin
        columns[lastIndex].header?.trailingMargin = "\(horizontalMargin)\(style.vertical)"
        columns[lastIndex].header?.corners = .init({
            $0.topLeading = style.horizontal
            $0.topTrailing = style.downAndLeft
            $0.bottomTrailing = style.verticalAndLeft
            $0.bottomLeading = style.horizontal
        })
    }
    
}

// MARK: - Table.BorderStyle

extension ASCIITable {
    
    public enum BorderStyle {
        case double
        case heavy
        case heavyQuadrupleDash
        case heavyTripleDash
        case light
        case lightQuadrupleDash
        case lightTripleDash
        
        var horizontal: Character {
            switch self {
            case .double: return .BoxDrawn.doubleHorizontal
            case .heavy: return .BoxDrawn.heavyHorizontal
            case .heavyQuadrupleDash: return .BoxDrawn.heavyQuadrupleDashHorizontal
            case .heavyTripleDash: return .BoxDrawn.heavyTripleDashHorizontal
            case .light: return .BoxDrawn.lightHorizontal
            case .lightQuadrupleDash: return .BoxDrawn.lightQuadrupleDashHorizontal
            case .lightTripleDash: return .BoxDrawn.lightTripleDashHorizontal
            }
        }

        var vertical: Character {
            switch self {
            case .double: return .BoxDrawn.doubleVertical
            case .heavy: return .BoxDrawn.heavyVertical
            case .heavyQuadrupleDash: return .BoxDrawn.heavyQuadrupleDashVertical
            case .heavyTripleDash: return .BoxDrawn.heavyTripleDashVertical
            case .light: return .BoxDrawn.lightVertical
            case .lightQuadrupleDash: return .BoxDrawn.lightQuadrupleDashVertical
            case .lightTripleDash: return .BoxDrawn.lightTripleDashVertical
            }
        }

        var downAndLeft: Character {
            switch self {
            case .double: return .BoxDrawn.doubleDownAndLeft
            case .heavy: return .BoxDrawn.heavyDownAndLeft
            case .heavyQuadrupleDash: return .BoxDrawn.heavyDownAndLeft
            case .heavyTripleDash: return .BoxDrawn.heavyDownAndLeft
            case .light: return .BoxDrawn.lightDownAndLeft
            case .lightQuadrupleDash: return .BoxDrawn.lightDownAndLeft
            case .lightTripleDash: return .BoxDrawn.lightDownAndLeft
            }
        }

        var downAndRight: Character {
            switch self {
            case .double: return .BoxDrawn.doubleDownAndRight
            case .heavy: return .BoxDrawn.heavyDownAndRight
            case .heavyQuadrupleDash: return .BoxDrawn.heavyDownAndRight
            case .heavyTripleDash: return .BoxDrawn.heavyDownAndRight
            case .light: return .BoxDrawn.lightDownAndRight
            case .lightQuadrupleDash: return .BoxDrawn.lightDownAndRight
            case .lightTripleDash: return .BoxDrawn.lightDownAndRight
            }
        }

        var upAndLeft: Character {
            switch self {
            case .double: return .BoxDrawn.doubleUpAndLeft
            case .heavy: return .BoxDrawn.heavyUpAndLeft
            case .heavyQuadrupleDash: return .BoxDrawn.heavyUpAndLeft
            case .heavyTripleDash: return .BoxDrawn.heavyUpAndLeft
            case .light: return .BoxDrawn.lightUpAndLeft
            case .lightQuadrupleDash: return .BoxDrawn.lightUpAndLeft
            case .lightTripleDash: return .BoxDrawn.lightUpAndLeft
            }
        }

        var upAndRight: Character {
            switch self {
            case .double: return .BoxDrawn.doubleUpAndRight
            case .heavy: return .BoxDrawn.heavyUpAndRight
            case .heavyQuadrupleDash: return .BoxDrawn.heavyUpAndRight
            case .heavyTripleDash: return .BoxDrawn.heavyUpAndRight
            case .light: return .BoxDrawn.lightUpAndRight
            case .lightQuadrupleDash: return .BoxDrawn.lightUpAndRight
            case .lightTripleDash: return .BoxDrawn.lightUpAndRight
            }
        }

        var upAndHorizontal: Character {
            switch self {
            case .double: return .BoxDrawn.doubleUpAndHorizontal
            case .heavy: return .BoxDrawn.heavyUpAndHorizontal
            case .heavyQuadrupleDash: return .BoxDrawn.heavyUpAndHorizontal
            case .heavyTripleDash: return .BoxDrawn.heavyUpAndHorizontal
            case .light: return .BoxDrawn.lightUpAndHorizontal
            case .lightQuadrupleDash: return .BoxDrawn.lightUpAndHorizontal
            case .lightTripleDash: return .BoxDrawn.lightUpAndHorizontal
            }
        }

        var downAndHorizontal: Character {
            switch self {
            case .double: return .BoxDrawn.doubleDownAndHorizontal
            case .heavy: return .BoxDrawn.heavyDownAndHorizontal
            case .heavyQuadrupleDash: return .BoxDrawn.heavyDownAndHorizontal
            case .heavyTripleDash: return .BoxDrawn.heavyDownAndHorizontal
            case .light: return .BoxDrawn.lightDownAndHorizontal
            case .lightQuadrupleDash: return .BoxDrawn.lightDownAndHorizontal
            case .lightTripleDash: return .BoxDrawn.lightDownAndHorizontal
            }
        }

        var verticalAndLeft: Character {
            switch self {
            case .double: return .BoxDrawn.doubleVerticalAndLeft
            case .heavy: return .BoxDrawn.heavyVerticalAndLeft
            case .heavyQuadrupleDash: return .BoxDrawn.heavyVerticalAndLeft
            case .heavyTripleDash: return .BoxDrawn.heavyVerticalAndLeft
            case .light: return .BoxDrawn.lightVerticalAndLeft
            case .lightQuadrupleDash: return .BoxDrawn.lightVerticalAndLeft
            case .lightTripleDash: return .BoxDrawn.lightVerticalAndLeft
            }
        }

        var verticalAndRight: Character {
            switch self {
            case .double: return .BoxDrawn.doubleVerticalAndRight
            case .heavy: return .BoxDrawn.heavyVerticalAndRight
            case .heavyQuadrupleDash: return .BoxDrawn.heavyVerticalAndRight
            case .heavyTripleDash: return .BoxDrawn.heavyVerticalAndRight
            case .light: return .BoxDrawn.lightVerticalAndRight
            case .lightQuadrupleDash: return .BoxDrawn.lightVerticalAndRight
            case .lightTripleDash: return .BoxDrawn.lightVerticalAndRight
            }
        }

        var verticalAndHorizontal: Character {
            switch self {
            case .double: return .BoxDrawn.doubleVerticalAndHorizontal
            case .heavy: return .BoxDrawn.heavyVerticalAndHorizontal
            case .heavyQuadrupleDash: return .BoxDrawn.heavyVerticalAndHorizontal
            case .heavyTripleDash: return .BoxDrawn.heavyVerticalAndHorizontal
            case .light: return .BoxDrawn.lightVerticalAndHorizontal
            case .lightQuadrupleDash: return .BoxDrawn.lightVerticalAndHorizontal
            case .lightTripleDash: return .BoxDrawn.lightVerticalAndHorizontal
            }
        }
    }
    
}
