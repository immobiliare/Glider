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

extension Date {
    
    private static let dateFormatter = DateFormatter()
    
    internal func formatAs(_ dateFormat: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
                         locale: String = "en_US_POSIX",
                         timeZone: String = "") -> String {
        Date.dateFormatter.locale = Locale(identifier: locale)
        Date.dateFormatter.dateFormat = dateFormat
        Date.dateFormatter.timeZone = TimeZone(identifier: timeZone)
        return Date.dateFormatter.string(from: self)
    }
    
}
