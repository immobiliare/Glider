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

#if os(iOS)

extension UIDevice {
    
    var isCharging: Bool {
        isBatteryMonitoringEnabled = true
        return batteryState != .unplugged
    }
    
}

#endif

#if os(iOS) || os(tvOS)
import UIKit

extension UIDevice {
    
    var isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }
    
    var distribution: Distribution {
        if isTestsSuite {
            return .xcTests
        }
        
        if isDistributionAppStore {
            return .appStore
        }
        
        if isDistributionTestFlight {
            return .testFlight
        }
        
        return .xCodeDebug
    }
    
    // MARK: - Private
    
    private var isDistributionTestFlight: Bool {
        #if DEBUG
        return false
        #else
        guard let path = Bundle.main.appStoreReceiptURL?.path else {
            return false
        }
        return path.contains("sandboxReceipt")
        #endif
    }
    
    private var isDistributionAppStore: Bool {
        do {
            guard let receiptUrl = Bundle.main.appStoreReceiptURL else {
                return false
            }
            _ = try Data(contentsOf: receiptUrl)
            return true
        } catch {
            return false
        }
    }
    
    private var isTestsSuite: Bool {
        return NSClassFromString("XCTest") != nil
    }
    
}

// MARK: - Distribution

internal enum Distribution: CustomStringConvertible {
    case xcTests
    case testFlight
    case appStore
    case xCodeDebug
    
    public var description: String {
        switch self {
        case .xcTests: return "XCTests"
        case .testFlight: return "testflight"
        case .appStore: return "appstore"
        case .xCodeDebug: return "xcode"
        }
    }
    
}

// MARK: - UIUserInterfaceIdiom

extension UIUserInterfaceIdiom: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .phone: return "iPhone"
        case .pad: return "iPad"
        case .tv: return "AppleTV"
        case .carPlay: return "carPlay"
        default: return "Unkwnown"
        }
    }
    
}

#endif

#if os(iOS)

// MARK: - UIDeviceOrientation

extension UIDeviceOrientation: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .landscapeLeft, .landscapeRight: return "landscape"
        case .portrait, .portraitUpsideDown: return "portrait"
        case .unknown: return "unknown"
        case .faceUp: return "faceup"
        case .faceDown: return "facedown"
        @unknown default: return "unknown"
        }
    }

}

#endif

// MARK: - CGSize

extension CGSize: CustomStringConvertible {
    
    public var description: String {
        "\(width)x\(height)"
    }
    
}
