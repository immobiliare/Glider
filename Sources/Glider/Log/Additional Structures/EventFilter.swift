//
//  File.swift
//  
//
//  Created by Daniele Margutti on 29/04/22.
//

import Foundation

public protocol EventFilter {
    
    /// Called to determine whether the given `Log.Payload` should be recorded.
    /// - Parameter payload: The payload  to be evaluated by the filter.
    func shouldWrite(_ event: Event) -> Bool
    
}
