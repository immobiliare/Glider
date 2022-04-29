//
//  File.swift
//  
//
//  Created by Daniele Margutti on 26/04/22.
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
    public internal(set) var runtimeContext: RuntimeContext?
    
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
        public let function: String?
        
        /// Identify the file path called by the log (stack trace).
        public let filePath: String?
        
        /// Name of the file called by the log.
        public var fileName: String? {
            ((filePath ?? "") as NSString).lastPathComponent
        }
        
        /// Identify the file line called by the log (stack trace).
        public private(set) var fileLine: Int?
        
        /// Calling thread id.
        public private(set) var threadID: UInt64?
     
        // MARK: - Initialization
        
        /// Initialize a new runtime context with the information coming from the stacktrace.
        ///
        /// - Parameters:
        ///   - function: function called.
        ///   - filePath: file path origin of the call.
        ///   - fileLine: file line origin of the call.
        internal init(function: String, filePath: String, fileLine: Int) {
            self.function = function
            self.filePath = filePath
            self.fileLine = fileLine
            self.threadID = ProcessIdentification.threadID()
        }
        
    }
    
}
