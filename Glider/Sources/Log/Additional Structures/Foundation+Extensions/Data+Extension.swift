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

extension Data {
    
    /// Get the UTF8 representation of the binary data when it represent a text.
    ///
    /// - Returns: `String`
    public func asString() throws -> String {
        String(data: self, encoding: .utf8) ?? ""
    }
    
}
