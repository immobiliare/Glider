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

/// Used to handle safe unwrapping of optional objects.
protocol AnOptional {
    
    /// Return `true` if optional contains a `nil` value.
    var isNil: Bool { get }

}

extension Optional: AnOptional {
    
    public var isNil: Bool {
        // swiftlint:disable unused_closure_parameter
        guard let hasValue = self.map({ (value: Wrapped) -> Bool in
            return true
        }) else {
            return true
        }
        
        return !hasValue
    }
    
}
