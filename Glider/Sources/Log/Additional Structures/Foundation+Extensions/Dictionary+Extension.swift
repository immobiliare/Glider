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

import Foundation

extension Dictionary {
    
    /// Merge the content of `baseDictionary` with additional data coming from `additionalData`.
    /// `additionalData` may override existing keys with new values on conflicts.
    ///
    /// - Parameters:
    ///   - baseDictionary: base dictionary.
    ///   - additionalData: dictionary to merge.
    /// - Returns: `[Key: Value]`
    internal static func merge(baseDictionary: [Key: Value], additionalData: [Key: Value]?) -> [Key: Value] {
        guard let additionalData = additionalData else {
            return baseDictionary
        }
        
        let result = baseDictionary.merging(additionalData, uniquingKeysWith: { (_, new) in
            new
        })
        return result
    }
    
}
