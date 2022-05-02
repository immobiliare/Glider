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
/*
public struct ContextsOptions: OptionSet {
    public let rawValue: Int32
    
    // Opening options
    public static let readOnly = Options(rawValue: SQLITE_OPEN_READONLY)

    public static let `default`:  Options = [
        .readWrite, .create, .fullMutex
    ]
    public static let all: Options = [
        .readOnly, .readWrite, .create,
        .noMutex, .fullMutex,
        .sharedCache, .privateCache
    ]
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}
*/
