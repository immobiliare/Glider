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

// MARK: - Scope

public struct Scope {
    
    /// Set global user -> thus will be sent with every event.
    public var user: User?
    
    /// Tags are key/value string pairs.
    /// Some transports may index and make them searchable (like sentry).
    public private(set) var tags: [String: String]?
    
    /// Runtime context attributes captured.
    public internal(set) var runtimeContext = RuntimeContext()
    
    /// Sets the fingerprint in the scope.
    /// A fingerprint is a way to uniquely identify an error, and all events have one.
    /// Events with the same fingerprint may be grouped together into an issue depending
    /// on the transport service used.
    /// (For example Sentry group them in a single issue).
    public var fingerprint: String?
    
    // MARK: - Initialization
    
    public init() {

    }
    
}

// MARK: - Scope.RuntimeContext

extension Scope {
    
    public struct RuntimeContext {
        
        // MARK: - Public Properties
        
        /// Identify the function name called by the log (stack trace).
        public private(set) var function: String?
        
        /// Identify the file path called by the log (stack trace).
        public private(set) var filePath: String?
        
        /// Name of the file called by the log.
        public var fileName: String? {
            ((filePath ?? "") as NSString).lastPathComponent
        }
        
        /// Identify the file line called by the log (stack trace).
        public private(set) var fileLine: Int?
        
        /// Calling thread id.
        public let threadID = ProcessIdentification.threadID()
     
        // MARK: - Internal Function
        
        /// Attach calle informations to the runtime context.
        ///
        /// - Parameters:
        ///   - function: function called.
        ///   - filePath: file path origin of the call.
        ///   - fileLine: file line origin of the call.
        internal mutating func attach(function: String? = nil, filePath: String? = nil, fileLine: Int? = nil) {
            self.function = function
            self.filePath = filePath
            self.fileLine = fileLine
        }

    }
    
}
