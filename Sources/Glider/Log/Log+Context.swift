//
//  File.swift
//  
//
//  Created by Daniele Margutti on 20/04/22.
//

import Foundation

extension Log {
    
    public struct Contexts {
        
        /// Device context describes the device that caused the event.
        /// This is most appropriate for mobile applications.
        public var device: Context
        
        /// OS context describes the operating system on which
        /// the crash happened/the event was created.
        public var os: Context
        
        
    }
    
}

extension Log.Contexts {
    
    public struct Context {
        
        public var values: [String: Any]
        
    }
    
}
