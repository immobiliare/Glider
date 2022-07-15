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

extension Dictionary {
    
    public func valueAtKeyPath<T>(_ keyPath: String) -> T? {
        var keys = keyPath.components(separatedBy: ".")
        guard let first = keys.first as? Key else {
            debugPrint("Unable to use string as key on type: \(Key.self)")
            return nil
        }
        
        guard let value = self[first] else {
            return nil
        }
        
        keys.remove(at: 0)
        if !keys.isEmpty, let subDict = value as? [String : Any?] {
            let rejoined = keys.joined(separator: ".")
            
            return subDict.valueAtKeyPath(rejoined)
        }
        return value as? T
    }
    
}

extension StringProtocol {

    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
    
    subscript(range: Range<Int>) -> SubSequence {
        let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
        return self[startIndex..<index(startIndex, offsetBy: range.count)]
    }
    
    subscript(range: ClosedRange<Int>) -> SubSequence {
        let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
        return self[startIndex..<index(startIndex, offsetBy: range.count)]
    }
    
    subscript(range: PartialRangeFrom<Int>) -> SubSequence {
        self[index(startIndex, offsetBy: range.lowerBound)...]
    }
    
    subscript(range: PartialRangeThrough<Int>) -> SubSequence {
        self[...index(startIndex, offsetBy: range.upperBound)]
    }
    
    subscript(range: PartialRangeUpTo<Int>) -> SubSequence {
        self[..<index(startIndex, offsetBy: range.upperBound)]
    }

}

