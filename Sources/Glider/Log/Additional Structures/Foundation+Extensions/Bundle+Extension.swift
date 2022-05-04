//
//  File.swift
//  
//
//  Created by Daniele Margutti on 04/05/22.
//

import Foundation

extension Bundle {
    
    static var appName: String {
        Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? ""
    }
    
    static var buildVersionNumber: String {
        Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? ""
    }
    
    static var releaseVersionNumber: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    static var bundleID: String {
        Bundle.main.infoDictionary?[kCFBundleIdentifierKey as String] as? String ?? ""
    }
    
}
