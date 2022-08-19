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

extension String {
    
    /// Truncation style of the string.
    public enum TruncationStyle {
        
        /// Truncation at head with a fixed length.
        case head(length: Int)
        
        /// Truncation at middle of the string with fixed length.
        case middle(length: Int)
        
        /// Truncation at tail of the string with fixed length.
        case tail(length: Int)
        
        /// Length of the truncation
        fileprivate var length: Int {
            switch self {
            case .head(let l): return l
            case .middle(let l): return l
            case .tail(let l): return l
            }
        }
        
    }
    
    /// Padding style for string.
    public enum PaddingStyle {
        /// Left padding of the text.
        case left(columns: Int)
        
        /// Right padding of the text.
        case right(columns: Int)
        
        /// Center padding of the text.
        case center(columns: Int)
    }
    
    /// Tranformation function for a string.
    public typealias Transform = ((String) -> String)
 
}

extension String {
    
    /// Split a string with a given column width.
    ///
    /// - Parameter width: max width.
    /// - Returns: `String`
    internal func split(toWidth width: Int?, separator: String = "\n") -> String {
        guard let width = width, count > width else {
            return self
        }
        
        var result = [String]()
        
        for i in stride(from: 0, to: self.count, by: width) {
            let endIndex = self.index(self.endIndex, offsetBy: -i)
            let startIndex = self.index(endIndex, offsetBy: -width, limitedBy: self.startIndex) ?? self.startIndex
            result.insert(String(self[startIndex..<endIndex]), at: 0)
        }
        
        return result.joined(separator: separator)
    }
    
    /// Truncate string at given limit.
    ///
    /// - Parameters:
    ///   - style: style of truncation, by default is `.tail`
    ///   - leader: leader suffix to happend, by default is `…`
    /// - Returns: `String`
    internal func trunc(_ style: TruncationStyle?, leader: String = "…") -> String {
        guard let style = style, self.count > style.length else { return self }

        switch style {
        case .head:
            return leader + self.suffix(style.length)
        case .middle:
            let headCharactersCount = Int(ceil(Float(style.length - leader.count) / 2.0))

            let tailCharactersCount = Int(floor(Float(style.length - leader.count) / 2.0))

            return "\(self.prefix(headCharactersCount))\(leader)\(self.suffix(tailCharactersCount))"
        case .tail:
            return self.prefix(style.length) + leader
        }
    }
    
    /// Pad receiver string with passed style.
    ///
    /// - Parameters:
    ///   - style: style of padding.
    ///   - filler: filler used for padding (space if not specified).
    /// - Returns: `String`
    public func padded(_ style: PaddingStyle?, filler: Character = " ") -> String {
        guard let style = style else {
            return self
        }
        
        return style.pad(text: self, length: style.columnsLength, filler: filler)
    }
    
    // MARK: - Internal Function
    
    /// Wipe characters from string.
    ///
    /// - Parameter characters: characters to remove.
    /// - Returns: `String`
    func wipeCharacters(characters: String) -> String {
        return replaceCharacters(characters: characters, toSeparator: "")
    }
    
    // MARK: - Internal Function

    private func replaceCharacters(characters: String, toSeparator: String) -> String {
        let characterSet = CharacterSet(charactersIn: characters)
        let components = self.components(separatedBy: characterSet)
        return components.joined(separator: toSeparator)
    }
    
    internal func deletingFilePathExtension() -> String {
        return (self as NSString).deletingPathExtension
    }
    
}

extension String.PaddingStyle {
    
    internal func pad(text: String, length: Int, filler: Character = " ") -> String {
        let padding: String = {
            let byteLength = text.lengthOfBytes(using: String.Encoding.utf32) / 4

            guard length > byteLength else { return "" }

            let paddingLength = length - byteLength

            return String(repeating: String(filler), count: paddingLength)
        }()

        switch self {
        case .left:
            return text + padding
        case .right:
            return padding + text
        case .center:
            let halfDistance = padding.distance(from: padding.startIndex, to: padding.endIndex) / 2
            let halfIndex = padding.index(padding.startIndex, offsetBy: halfDistance)
            let leftHalf = padding[..<halfIndex]
            let rightHalf = padding[halfIndex...]
            return leftHalf + text + rightHalf
        }
    }
    
    fileprivate var columnsLength: Int {
        switch self {
        case .left(columns: let c): return c
        case .center(columns: let c): return c
        case .right(columns: let c): return c
        }
    }
    
}

extension String {
    
    /// Format a string with given placeholders.
    ///
    /// - Parameters:
    ///   - format: format.
    ///   - value: value to apply.
    /// - Returns: `String`
    internal static func format(_ format: String?, value: String) -> String {
        let unwrappedFormat = format ?? "%@"
        return NSString(format: unwrappedFormat as NSString, value) as String
    }
    
}
