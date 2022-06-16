//
//  File.swift
//  
//
//  Created by Daniele Margutti on 24/05/22.
//

import Foundation

extension Data {
    
    public func asString() throws -> String {
        String(data: self, encoding: .utf8) ?? ""
    }
    
}
