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
    
    public enum TruncationStyle {
        case head(length: Int)
        case middle(length: Int)
        case tail(length: Int)
        
        fileprivate var length: Int {
            switch self {
            case .head(let l): return l
            case .middle(let l): return l
            case .tail(let l): return l
            }
        }
    }
    
    public enum PaddingStyle {
        case left(columns: Int)
        case right(columns: Int)
        case center(columns: Int)
    }
    
    public typealias Transform = ((String) -> String)
 
}

extension String {
    
    /// Truncate string at given limit.
    ///
    /// - Parameters:
    ///   - style: style of truncation, by default is `.tail`
    ///   - leader: leader suffix to happend, by default is `…`
    /// - Returns: String
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
    
    public func padded(_ style: PaddingStyle?, filler: Character = " ") -> String {
        guard let style = style else {
            return self
        }
        
        return style.pad(text: self, length: style.columnsLength, filler: filler)
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
    
    internal static func format(_ format: String?, value: String) -> String {
        let unwrappedFormat = format ?? "%@"
        return NSString(format: unwrappedFormat as NSString, value) as String
    }
    
}
