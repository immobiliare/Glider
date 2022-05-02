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

/// The following struct is used to retrive the standard information about
/// the context where GliderSDK is running in.
internal struct ProcessIdentification {
    
    // this ensures we only look up process info once
    public static var shared = ProcessIdentification()
    
    /// Name of the process.
    public let processName: String
    
    /// ID of the process.
    public let processID: Int32
    
    /// Application's short version.
    public lazy var version: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }()
    
    /// Application's build number.
    public lazy var buildNumber: String = {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }()
    
    /// Application's bundle identifier.
    public lazy var bundleID: String = {
        Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
    }()
    
    /// Full application's information
    public lazy var applicationInfo: String = {
        "\(bundleID)/\(version).\(buildNumber)"
    }()

    private init() {
        let process = ProcessInfo.processInfo
        processName = process.processName
        processID = process.processIdentifier
    }
    
    public static func threadID() -> UInt64 {
        var threadID: UInt64 = 0
        pthread_threadid_np(nil, &threadID)
        return threadID
    }
    
}
