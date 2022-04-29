//
//  File.swift
//  
//
//  Created by Daniele Margutti on 29/04/22.
//

import Foundation

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
