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
#if os(iOS) || os(tvOS)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

// MARK: - Context

/// The `Context` struct encapsulate all the relevant information about
/// the current state of device including Operating System runtime attributes
/// (memory, disk...) and Device Attributes (like OS version, model, display size).
public struct Context: Codable {
    public typealias OSAttributes = [OSKeys: String]
    public typealias DeviceAttributes = [DeviceKeys: String]

    // MARK: - Public Properties
    
    /// Device related context attributes.
    public let device: DeviceAttributes?
    
    /// Operating System related context attributes.
    public let os: OSAttributes?
    
    // MARK: - Initialization

    /// Initialize a new set of context attributes.
    ///
    /// - Parameters:
    ///   - device: device attributes
    ///   - os: os attributes
    internal init(device: DeviceAttributes?, os: OSAttributes?) {
        self.device = device
        self.os = os
    }
    
}

// MARK: - Context Keys

extension Context {
    
    public enum OSKeys: String, Codable {
        case name, version, theme
    }
    
    public enum DeviceKeys: String, Codable {
        // swiftlint:disable identifier_name
        case hostname, family, model
        case screen_resolution, screen_density
        case build_type, simulator
        case app_name, app_version, app_identifier, app_build
        case orientation, charging, battery_level
        case online, timezone
        case free_disk_space, total_disk_space, used_disk_space
        case low_memory, memory_size, free_memory, used_memory, total_memory
    }
    
}

// MARK: - ContextsData

internal class ContextsData {
    
    // MARK: - Public Properties
    
    /// Shared instance
    public static let shared = ContextsData()
    
    // MARK: - Private Properties
    
    private let queue = DispatchQueue(label: "com.glider.contextdata")
    
    /// Device context attributes
    private var device = Context.DeviceAttributes()
    
    /// OS context attributes
    private var os = Context.OSAttributes()
    
    /// Last Update date of the context.
    fileprivate var lastUpdate: Date?
    
    /// Should the dynamic data be updated?
    fileprivate var shouldUpdateData: Bool {
        guard let lastUpdate = lastUpdate else {
            lastUpdate = Date()
            return true
        }
        
        let interval = Date().timeIntervalSince(lastUpdate)
        return interval > GliderSDK.shared.contextsCaptureFrequency.lifetimeInterval
    }
    
    // MARK: - Initialization
    
    private init() {
        setupDeviceStaticAttributes()
        setupOSStaticAttributes()
    }
    
    // MARK: - Public Functions
    
    /// Get the current captured context.
    ///
    /// - Returns: Context
    public func captureContext() -> Context {
        if shouldUpdateData {
            queue.sync {
                if GliderSDK.shared.contextsCaptureOptions.contains(.device) {
                    updateDeviceDynamicAttributes()
                }
                
                if GliderSDK.shared.contextsCaptureOptions.contains(.os) {
                    updateOSDynamicAttributes()
                }
            }
        }
        
        return Context(
            device: (GliderSDK.shared.contextsCaptureOptions.contains(.device) ? device : nil),
            os: (GliderSDK.shared.contextsCaptureOptions.contains(.os) ? os : nil)
        )
    }
    
    // MARK: - Private Functions
    
    private func setupOSStaticAttributes() {
        #if os(macOS)
        os[.name] = "macos"
        os[.version] = ProcessInfo.processInfo.operatingSystemVersionString
        #else
        os[.name] = UIDevice.current.systemName
        os[.version] = UIDevice.current.systemVersion
        #endif
    }
    
    private func updateOSDynamicAttributes() {
        if #available(iOS 13.0, *) {
#if os(macOS)
            os[.theme] = (NSAppearance.current?.name == .aqua ? "light": "dark")
#elseif os(iOS)
            os[.theme] = (UITraitCollection.current.userInterfaceStyle == .dark ? "dark" : "light")
#endif
        }
    }
    
    private func setupDeviceStaticAttributes() {
        #if os(iOS) || os(tvOS)
        device[.hostname] = UIDevice.current.name
        device[.family] = UIDevice.current.userInterfaceIdiom.description
        device[.model] = UIDevice.current.model
        device[.screen_resolution] = UIScreen.main.bounds.size.description
        device[.screen_density] = UIScreen.main.scale.description
        device[.build_type] = UIDevice.current.distribution.description
        device[.simulator] = UIDevice.current.isSimulator.description
        #endif
        
        device[.app_name] = Bundle.appName
        device[.app_version] = Bundle.releaseVersionNumber
        device[.app_build] = Bundle.buildVersionNumber
        device[.app_identifier] = Bundle.bundleID
    }
    
    private func updateDeviceDynamicAttributes() {
        #if os(iOS)
        device[.orientation] = UIDevice.current.orientation.description
        device[.charging] = UIDevice.current.isCharging.description
        device[.battery_level] = (UIDevice.current.isBatteryMonitoringEnabled ? UIDevice.current.batteryLevel.description : "0")
        #endif
        
        // Other
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, *) {
            device[.online] = StatusMonitor.Network.current.isNetworkAvailable().description
        }
        device[.timezone] = TimeZone.current.identifier

        // Disk
        device[.free_disk_space] = String(StatusMonitor.Disk.freeDiskSpaceInBytes)
        device[.total_disk_space] = String(StatusMonitor.Disk.totalDiskSpaceInBytes)
        device[.used_disk_space] = String(StatusMonitor.Disk.usedDiskSpaceInBytes)

        // Memory
        device[.low_memory] = StatusMonitor.Memory.current.isLowMemory.description
        device[.memory_size] = String(StatusMonitor.Memory.current.totalMemoryBytes)
        device[.free_memory] = String(StatusMonitor.Memory.current.freeMemoryBytes)
        device[.used_memory] = String(StatusMonitor.Memory.current.usedMemoryBytes)
        device[.total_memory] = String(StatusMonitor.Memory.current.totalMemoryBytes)
    }
        
}

// MARK: - ContextsCaptureOptions

/// The following bitmask is used to configure what kind of context
/// attributes should be captured along a new event.
/// Capturing context options is not a zero-effort operations (even when
/// you set a relaxed update frequency) so you should use these options
/// with caution.
///
/// By default only the `runtime` context is captured.
public struct ContextsCaptureOptions: OptionSet {
    public let rawValue: Int
    
    /// Capture the runtime context, including calling function, file and line.
    public static let device = ContextsCaptureOptions(rawValue: 1 << 0)
    
    /// Capture the operating system context.
    public static let os = ContextsCaptureOptions(rawValue: 2 << 0)

    /// All flags are active.
    public static let all: ContextsCaptureOptions = [.device, .os]
    
    /// Default options does not include any additional contexts.
    public static let none: ContextsCaptureOptions = []
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// The following enum describe the frequency of updates for context attributes.
public enum ContextCaptureFrequency {
    /// contexts are captured with a semi real-time update. Collected
    /// data are fresh but require additional resources.
    case `strict`
    
    /// this is the default options. Data maybe not so fresh but still
    /// relevant for the most type of usage.
    case `default`
    
    /// a relaxed refresh is used when you don't need to strictly updated
    /// data, but you can still use it.
    case relaxed
    
    /// Lifetime interval of the context captured session, expressed in seconds.
    fileprivate var lifetimeInterval: TimeInterval {
        switch self {
        case .`strict`:     return 0.3
        case .`default`:    return 5
        case .relaxed:      return 20
        }
    }
    
}
