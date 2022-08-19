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

extension Data {
    
    /// Get the UTF8 representation of the binary data when it represent a text.
    ///
    /// - Returns: `String`
    public func asString() throws -> String {
        String(data: self, encoding: .utf8) ?? ""
    }
    
}
