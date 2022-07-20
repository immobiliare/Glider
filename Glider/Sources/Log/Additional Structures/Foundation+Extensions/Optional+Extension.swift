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

protocol AnOptional {
    
    /// Return `true` if optional contains a `nil` value.
    var isNil: Bool { get }

}

extension Optional : AnOptional {

    public var isNil: Bool {
        get {
            guard let hasValue = self.map({ (value: Wrapped) -> Bool in
                return true
            }) else {
                return true
            }

            return !hasValue
        }
    }

}
