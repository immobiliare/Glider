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
    
    /// Merge the content of `baseDictionary` with additional data coming from `additionalData`.
    /// `additionalData` may override existing keys with new values on conflicts.
    ///
    /// - Parameters:
    ///   - baseDictionary: base dictionary.
    ///   - additionalData: dictionary to merge.
    /// - Returns: `[Key: Value]`
    internal static func merge(baseDictionary: [Key: Value], additionalData:  [Key: Value]?) ->  [Key: Value] {
        guard let additionalData = additionalData else {
            return baseDictionary
        }
        
        let result = baseDictionary.merging(additionalData, uniquingKeysWith: { (_, new) in
            new
        })
        return result
    }
    
}
