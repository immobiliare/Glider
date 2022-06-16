//
//  File.swift
//  
//
//  Created by Daniele Margutti on 25/05/22.
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
