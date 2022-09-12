//
//  Glider
//  Fast, Lightweight yet powerful logging system for Swift.
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Authors:
//   - Daniele Margutti <hello@danielemargutti.com>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

extension Bundle {
    
    /// Name of the main application.
    static var appName: String {
        Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? ""
    }
    
    /// Build version number.
    static var buildVersionNumber: String {
        Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? ""
    }
    
    /// Release version number.
    static var releaseVersionNumber: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    /// Bundle ID.
    static var bundleID: String {
        Bundle.main.infoDictionary?[kCFBundleIdentifierKey as String] as? String ?? ""
    }
    
}
