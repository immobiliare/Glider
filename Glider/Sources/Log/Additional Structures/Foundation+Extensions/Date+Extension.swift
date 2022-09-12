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

extension Date {
    
    /// The static formatter used for better performace.
    private static let dateFormatter = DateFormatter()
    
    /// Format the current date to textualrepresentation.
    ///
    /// - Parameters:
    ///   - dateFormat: date format, ISO8601 if not specified.
    ///   - locale: locale, `en_US_POSIX` when not specified.
    ///   - timeZone: timezone, empty if not specified.
    ///
    /// - Returns: `String`
    internal func formatAs(_ dateFormat: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
                           locale: String = "en_US_POSIX",
                           timeZone: String = "") -> String {
        Date.dateFormatter.locale = Locale(identifier: locale)
        Date.dateFormatter.dateFormat = dateFormat
        Date.dateFormatter.timeZone = TimeZone(identifier: timeZone)
        return Date.dateFormatter.string(from: self)
    }
    
}
