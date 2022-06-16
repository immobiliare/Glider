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
