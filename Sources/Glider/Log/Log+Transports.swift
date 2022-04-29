//
//  File.swift
//  
//
//  Created by Daniele Margutti on 20/04/22.
//

import Foundation

public protocol LogTransports {
    
    @discardableResult
    func record(payload: Log.Payload) -> Bool
    
}
