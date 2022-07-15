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
//  The following code was inspired by <https://github.com/juri/TableDraw>.

import Foundation

extension ASCIITable: TerminalDisplay {
    
    /// Return the formatted terminal ready table.
    public var stringValue: String {
        
        let headerLines = self.columns.map {
            $0.header?.title.split(separator: "\n") ?? []
        }
        var columnWidths = [Int](repeating: 0, count: self.columns.count)

        var headerHeight: Int = 0
        var hasHeaderTopBorder = false
        var hasHeaderBottomBorder = false
        
        for (columnIndex, column) in zip(0..., columns) {
            guard let header = column.header else {
                continue
            }
            
            // Calculate header
            let lines = headerLines[columnIndex]
            let headerContentWidth = lines.reduce(0) { maxWidth, line in
                max(maxWidth, line.count)
            }
            let headerWidth = headerContentWidth + header.leadingMargin.count + header.trailingMargin.count
            columnWidths[columnIndex] = headerWidth

            let contentHeight = max(lines.count, header.minHeight)
            let height = contentHeight + header.decorationHeight
            headerHeight = max(headerHeight, height)
            hasHeaderTopBorder = hasHeaderTopBorder || header.topBorder != nil
            hasHeaderBottomBorder = hasHeaderBottomBorder || header.bottomBorder != nil
        }
        
        
        
        var columnIndex = -1
        var contentLines = [[Substring]]()
        var rowHeights = [Int]()
        var rowIndex = -1
        for content in self.content {
            columnIndex = ((columnIndex + 1) % self.columns.count)
            if columnIndex == 0 {
                rowIndex += 1
            }
            let column = self.columns[columnIndex]

            let text = content.stringValue
            let lines = String.split(string: text, byCount: column.maxWidth).split(separator: "\n")
            contentLines.append(lines)
            let oldRowHeight = columnIndex == 0 ? 0 : rowHeights[rowIndex]
            let newRowHeight = max(oldRowHeight, lines.count + column.verticalPadding.total)
            if rowIndex == rowHeights.count {
                rowHeights.append(newRowHeight)
            } else {
                rowHeights[rowIndex] = newRowHeight
            }
            let textWidth = (
                lines.reduce(0) { longest, line in max(longest, line.count) } +
                    column.leadingMargin.count +
                    column.trailingMargin.count
            )
            columnWidths[columnIndex] = max(textWidth, columnWidths[columnIndex])
        }
        
        let hasVisibleFooter = self.columns.contains(where: \.visibleFooter)
        let footerHeight = hasVisibleFooter ? 1 : 0
        let totalLineCount = rowHeights.reduce(0, +) + footerHeight
        var outputLines = [String](repeating: "", count: totalLineCount + headerHeight)

        // Draw headers
        let headerContentHeight = headerHeight - (hasHeaderTopBorder ? 1 : 0) - (hasHeaderBottomBorder ? 1 : 0)
        for (columnIndex, column) in zip(0..., self.columns) {
            let columnWidth = columnWidths[columnIndex]
            guard let header = column.header else {
                for lineIndex in 0 ..< headerHeight {
                    outputLines[lineIndex].append(String(repeating: " ", count: columnWidth))
                }
                continue
            }
            let lines = headerLines[columnIndex]
            let paddedLines = header.verticalPadding.apply(lines: lines)
            let verticallyAlignedLines = header.verticalAlignment.apply(
                text: paddedLines,
                height: headerHeight - (hasHeaderTopBorder ? 1 : 0) - (hasHeaderBottomBorder ? 1 : 0)
            )
            let horizontallyAlignedLines = header.horizontalAlignment
                .apply(
                    text: verticallyAlignedLines,
                    width: max(columnWidth - header.leadingMargin.count - header.trailingMargin.count, column.minWidth),
                    fillCharacter: header.fillCharacter
                )
                .map { line in
                    "\(header.leadingMargin)\(line)\(header.trailingMargin)"
                }
            if hasHeaderTopBorder {
                if let topBorder = header.topBorder {
                    let borderLength = (
                        columnWidth -
                            (header.corners.topLeading != nil ? 1 : 0) -
                            (header.corners.topTrailing != nil ? 1 : 0)
                    )
                    if let leftCorner = header.corners.topLeading {
                        outputLines[0].append(leftCorner)
                    }
                    outputLines[0].append(String(repeating: topBorder, count: borderLength))
                    if let rightCorner = header.corners.topTrailing {
                        outputLines[0].append(rightCorner)
                    }
                } else {
                    outputLines[0].append(String(repeating: " ", count: columnWidth))
                }
            }
            let outputStartIndex = hasHeaderTopBorder ? 1 : 0
            for lineIndex in 0 ..< headerContentHeight {
                outputLines[lineIndex + outputStartIndex].append(horizontallyAlignedLines[lineIndex])
            }
            if hasHeaderBottomBorder {
                if let bottomBorder = header.bottomBorder {
                    let borderLength = (
                        columnWidth -
                            (header.corners.bottomLeading != nil ? 1 : 0) -
                            (header.corners.bottomTrailing != nil ? 1 : 0)
                    )
                    if let leftCorner = header.corners.bottomLeading {
                        outputLines[headerHeight - 1].append(leftCorner)
                    }
                    outputLines[headerHeight - 1].append(String(repeating: bottomBorder, count: borderLength))
                    if let rightCorner = header.corners.bottomTrailing {
                        outputLines[headerHeight - 1].append(rightCorner)
                    }
                } else {
                    outputLines[headerHeight - 1].append(String(repeating: " ", count: columnWidth))
                }
            }
        }

        columnIndex = -1
        rowIndex = -1
        var startLine = headerHeight

        for contentCellLines in contentLines {
            columnIndex = ((columnIndex + 1) % self.columns.count)
            if columnIndex == 0 { rowIndex += 1 }
            let column = self.columns[columnIndex]
            let rowHeight = rowHeights[rowIndex]
            let columnWidth = columnWidths[columnIndex]
            let verticallyPaddedLines = column.verticalPadding.apply(lines: contentCellLines)
            let verticallyAlignedLines = verticallyPaddedLines.count < rowHeight
                ? column.verticalAlignment.apply(text: verticallyPaddedLines, height: rowHeight)
                : verticallyPaddedLines
            let horizontallyAlignedLines = column.horizontalAlignment
                .apply(
                    text: verticallyAlignedLines,
                    width: max(columnWidth - column.leadingMargin.count - column.trailingMargin.count, column.minWidth),
                    fillCharacter: column.fillCharacter
                )
                .map { line in
                    "\(column.leadingMargin)\(line)\(column.trailingMargin)"
                }

            for (lineIndex, line) in zip(0..., horizontallyAlignedLines) {
                outputLines[startLine + lineIndex] += line
            }
            if columnIndex == self.columns.count - 1 {
                startLine += rowHeight
            }
        }

        if hasVisibleFooter {
            let lastIndex = outputLines.endIndex - 1
            for (columnIndex, column) in zip(0..., self.columns) {
                let columnWidth = columnWidths[columnIndex]
                if let footer = column.footer {
                    let length = columnWidth - footer.cornerLength
                    if let corner = footer.leadingCorner {
                        outputLines[lastIndex].append(corner)
                    }
                    outputLines[lastIndex].append(String(repeating: footer.border ?? " ", count: length))
                    if let corner = footer.trailingCorner {
                        outputLines[lastIndex].append(corner)
                    }
                } else {
                    outputLines[lastIndex].append(String(repeating: " ", count: columnWidth))
                }
            }
        }

        return outputLines.joined(separator: "\n")
    }
    
}

// MARK: - String Extension

extension String {
 
    static func split(string: String, byCount n: Int?, breakableCharacters: [Character] = [" "]) -> String {
        guard let n = n else {
            return string
        }

        precondition(n > 0)
        guard !string.isEmpty && string.count > n else { return string }

        var string = string
        var startIndex = string.startIndex

        repeat {
            // Break a string into lines.
            var endIndex = string[string.index(after: startIndex)...].firstIndex(of: "\n") ?? string.endIndex
            if string.distance(from: startIndex, to: endIndex) > n {
                let wrappedLine = String.split(line: string[startIndex..<endIndex], byCount: n, breakableCharacters: breakableCharacters)
                string.replaceSubrange(startIndex..<endIndex, with: wrappedLine)
                endIndex = string.index(startIndex, offsetBy: wrappedLine.count)
            }

            startIndex = endIndex
        } while startIndex < string.endIndex
        return string
    }
    
    
    private static func split(line: Substring, byCount n: Int, breakableCharacters: [Character]) -> String {
        var line = String(line)
        var lineStartIndex = line.startIndex

        while line.distance(from: lineStartIndex, to: line.endIndex) > n {
            let maxLineEndIndex = line.index(lineStartIndex, offsetBy: n)

            if breakableCharacters.contains(line[maxLineEndIndex]) {
                // If line terminates at a breakable character, replace that character with a newline
                line.replaceSubrange(maxLineEndIndex...maxLineEndIndex, with: "\n")
                lineStartIndex = line.index(after: maxLineEndIndex)
            } else if let index = line[lineStartIndex..<maxLineEndIndex].lastIndex(where: { breakableCharacters.contains($0) }) {
                // Otherwise, find a breakable character that is between lineStartIndex and maxLineEndIndex
                line.replaceSubrange(index...index, with: "\n")
                lineStartIndex = index
            } else {
                // Finally, forcible break a word
                line.insert("\n", at: maxLineEndIndex)
                lineStartIndex = maxLineEndIndex
            }
        }

        return line
    }

}
