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

/// `EventFormatter`s are used to attempt to create string representations of
/// `Event` instances.
public protocol EventFormatter {
    
    /// Called to create a string representation of the passed-in event.
    /// 
    /// - Returns: A `String` representation of `entry`, or `nil` if the
    ///            receiver could not format the `LogEntry`.
    func format(event: Event) -> String?
    
}

extension Array where Element == EventFormatter {
    
    func format(event: Event) -> String? {
        for formatter in self {
            if let formattedString = formatter.format(event: event) {
                return formattedString
            }
        }
        
        return nil
    }
    
}
