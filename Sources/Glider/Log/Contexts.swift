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
