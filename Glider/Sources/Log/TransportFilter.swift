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

public protocol TransportFilter {
    
    // MARK: - Public Functions
    
    /// Called to determine whether the given `Log.Payload` should be recorded.
    /// - Parameter payload: The payload  to be evaluated by the filter.
    func shouldAccept(_ event: Event) -> Bool
    
}
