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
    
    // MARK: - Public Properties

    /// Set global user -> thus will be sent with every event.
    public var user: User?
    
    /// Tags are key/value string pairs.
    /// Some transports may index and make them searchable (like sentry).
    /// Values can be overriden by the event's `tags` informations.
    public var tags = Tags()
    
    /// Arbitrary additional information that will be sent with the event.
    /// Values can be overriden by the event's `extra` informations.
    public var extra = Metadata()

    /// Sets the fingerprint in the scope.
    /// A fingerprint is a way to uniquely identify an error, and all events have one.
    /// Events with the same fingerprint may be grouped together into an issue depending
    /// on the transport service used.
    /// (For example Sentry group them in a single issue).
    public var fingerprint: String?
    
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
    
    // MARK: - Contexts
    
    /// Device context describes the device that caused the event.
    /// This is most appropriate for mobile applications.
    public internal(set) var context: Context?
    
    /// Attach calle informations to the runtime context.
    ///
    /// - Parameters:
    ///   - function: function called.
    ///   - filePath: file path origin of the call.
    ///   - fileLine: file line origin of the call.
    internal mutating func captureContext() {
        guard GliderSDK.shared.contextsCaptureOptions != .none else {
            return // avoid to capture the context
        }
        
        self.context = ContextsData.shared.captureContext()
    }
    
    internal mutating func attach(function fName: String? = nil, filePath fPath: String? = nil, fileLine fLine: Int? = nil) {
        self.function = fName
        self.filePath = fPath
        self.fileLine = fLine
    }
    
}
