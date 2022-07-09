//
//  File.swift
//  
//
//  Created by Daniele Margutti on 09/07/22.
//

import Foundation

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#else
import AppKit
#endif

extension RemoteTransport {
    
    public enum PacketCode: UInt8 {
        case clientHello = 0 // PacketClientHello
        case serverHello = 1
        case pause = 2
        case resume = 3
        case logMessage = 4 // Regular message
        case logNewtworkMessage = 5 // Network message (multipart data)
        case ping = 6
    }
    
}

public protocol RemoteTransportPacket {
    var code: RemoteTransport.PacketCode { get }
    
    func encode() throws -> Data
    
    func decode(_ data: Data) throws -> Self
}

extension RemoteTransport {
    
    /// The following packet encapsulate the logic of a `Glider.Event`.
    public struct PacketEvent: RemoteTransportPacket {
        
        /// The packet code.
        public var code: RemoteTransport.PacketCode {
            switch event.kind {
            case .log:
                return .logMessage
            case .networkLog:
                return .logNewtworkMessage
            }
        }
        
        /// Event stored.
        public let event: Glider.Event
        
        // MARK: - Initialixation
        
        /// Initialize a new packet for a given event.
        ///
        /// - Parameter event: event instance.
        public init(event: Glider.Event) {
            self.event = event
        }
        
        // MARK: - Public Function
        
        public func encode() throws -> Data {
            fatalError()
        }
        
        public func decode(_ data: Data) throws -> RemoteTransport.PacketEvent {
            fatalError()
        }
    }
    
    // MARK: - PacketEmpty
    
    public struct PacketEmpty: RemoteTransportPacket {
        
        public let code: RemoteTransport.PacketCode
        
        public init(code: RemoteTransport.PacketCode) {
            self.code = code
        }
        
        public func encode() throws -> Data {
            Data()
        }
        
        public func decode(_ data: Data) throws -> RemoteTransport.PacketEmpty {
            fatalError()
        }
        
    }
    
    // MARK: - PacketClientHello
    
    public struct PacketClientHello: RemoteTransportPacket {
        
        public struct DeviceInfo: Codable {
            public let name: String
            public let model: String
            public let localizedModel: String
            public let systemName: String
            public let systemVersion: String
        }
        
        public struct AppInfo: Codable {
            public static let current = AppInfo()
            
            public let bundleIdentifier: String?
            public let name: String?
            public let version: String?
            public let build: String?
            
            private init() {
                self.bundleIdentifier = Bundle.main.bundleIdentifier
                self.name = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
                self.version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                self.build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            }
        }
        
        public let code: RemoteTransport.PacketCode = .clientHello
        
        public let deviceId: UUID?
        public let deviceInfo: DeviceInfo
        public let appInfo: AppInfo = .current
        
        public init() {
            #if os(iOS) || os(tvOS)
            let device = UIDevice.current
            self.deviceId = device.identifierForVendor
            self.deviceInfo = DeviceInfo(
                name: device.name,
                model: device.model,
                localizedModel: device.localizedModel,
                systemName: device.systemName,
                systemVersion: device.systemVersion
            )
            #elseif os(watchOS)
            let device = WKInterfaceDevice.current()
            self.deviceId = device.identifierForVendor
            self.deviceInfo = DeviceInfo(
                name: device.name,
                model: device.model,
                localizedModel: device.localizedModel,
                systemName: device.systemName,
                systemVersion: device.systemVersion
            )
            #else
            self.deviceId = nil
            self.deviceInfo = DeviceInfo(
                name: Host.current().name ?? "unknown",
                model: "unknown",
                localizedModel: "unknown",
                systemName: "macOS",
                systemVersion: ProcessInfo().operatingSystemVersionString
            )
            #endif
        }
        
        public func encode() throws -> Data {
            fatalError()
        }
        
        public func decode(_ data: Data) throws -> RemoteTransport.PacketClientHello {
            fatalError()
        }
        
    }
    
}
