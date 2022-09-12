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
#elseif os(watchOS)
import WatchKit
#elseif os(macOS)
import AppKit
#endif

extension RemoteTransport {
    
    /// Packet presets code.
    /// - `clientHello`: the message sent to send important information about the listening server.
    /// - `serverHello`: a reply to `clientHello`.
    /// - `pause`: pause client reception.
    /// - `resume`: resume client reception.
    /// - `message`: the data send with log.
    /// - `ping`: ping.
    public enum PacketCode: UInt8 {
        case clientHello = 0
        case serverHello = 1
        case pause = 2
        case resume = 3
        case message = 4
        case ping = 6
    }
    
}

// MARK: - RemoteTransportPacket

public protocol RemoteTransportPacket {
    var code: RemoteTransport.PacketCode { get }
    
    /// Encode the packet content.
    ///
    /// - Returns: `Data`
    func encode() throws -> Data
    
    /// Decode packet content.
    ///
    /// - Parameter data: data to decode.
    /// - Returns: `Self?`
    static func decode(_ packet: RemoteTransport.RawPacket) throws -> Self?
    
}

extension RemoteTransport {
    
    /// The following packet encapsulate the logic of a `Glider.Event`.
    public struct PacketEvent: RemoteTransportPacket {
        
        /// The packet code.
        public var code: RemoteTransport.PacketCode = .message
        
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
            try JSONEncoder().encode(event)
        }
        
        public static func decode(_ packet: RemoteTransport.RawPacket) throws -> RemoteTransport.PacketEvent? {
            guard let code = PacketCode(rawValue: packet.code),
                  code == .message else {
                throw GliderError(message: "Unknown code for event")
            }
            
            let event = try JSONDecoder().decode(Glider.Event.self, from: packet.body)
            return PacketEvent(event: event)
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
        
        public static func decode(_ packet: RemoteTransport.RawPacket) throws -> RemoteTransport.PacketEmpty? {
            guard let code =  PacketCode(rawValue: packet.code) else {
                throw GliderError(message: "Unknown code for event")
            }
            
            return .init(code: code)
        }
        
    }
    
    // MARK: - PacketClientHello
    
    public struct PacketHello: RemoteTransportPacket {
        
        public struct DeviceInfo: Codable {
            public let name: String
            public let model: String
            public let localizedModel: String
            public let systemName: String
            public let systemVersion: String
        }
        
        public struct AppInfo: Codable {
            public static let current = AppInfo()

            public let sdkVersion: String
            public let bundleIdentifier: String?
            public let name: String?
            public let version: String?
            public let build: String?
            
            private init() {
                self.sdkVersion = GliderSDK.version
                self.bundleIdentifier = Bundle.main.bundleIdentifier
                self.name = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
                self.version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                self.build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            }
        }
        
        public struct Info: Codable {
            /// Device unique identifier.
            public let deviceId: UUID?
            
            /// Device informations.
            public let deviceInfo: DeviceInfo
            
            /// Application informations.
            public let appInfo: AppInfo
            
            public init() {
                self.appInfo = .current
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
        }
        
        // MARK: - Public Properties
        
        /// Code of the message.
        public let code: RemoteTransport.PacketCode = .clientHello
        
        /// Data encoded.
        public private(set) var info: Info
        
        // MARK: - Initialization
        
        public init() {
            self.info = Info()
        }
        
        private init(info: Info) {
            self.info = info
        }
        
        // MARK: Encoding/Decoding
        
        public func encode() throws -> Data {
            try JSONEncoder().encode(info)
        }
        
        public static func decode(_ packet: RemoteTransport.RawPacket) throws ->  RemoteTransport.PacketHello? {
            let data = try JSONDecoder().decode(Info.self, from: packet.body)
            return .init(info: data)
        }
        
    }
    
}

extension RemoteTransport {
    
    // MARK: - RemoteEvent

    /// Identify a remote event received from the side.
    /// - `packet`: a raw packet has been received.
    /// - `error`: an error has occurred.
    /// - `completed`: when closing a connection.
    public enum RemoteEvent {
        case packet(RawPacket)
        case error(Error)
        case completed
    }
    
    // MARK: - RawPacket
    
    /// The raw packet representation.
    public struct RawPacket {
        
        /// Raw control code.
        public let code: UInt8
        
        /// Content of the message.
        public let body: Data
        
        /// Readable control code
        public var readableCode: RemoteTransport.PacketCode? {
            .init(rawValue: code)
        }
        
    }
    
    // MARK: - PacketParsingError
    
    /// Parsing errors.
    enum PacketParsingError: Error {
        case notEnoughData
        case unsupportedContentSize
    }
    
    // MARK: - PacketHeader

    /// This is the structure of a raw data received or sent to the other side.
    /// It's structured as `|code|contentSize|body?|``
    struct PacketHeader {
        
        /// Identifier of the data.
        let code: UInt8

        /// Size of the incoming data.
        let contentSize: UInt32
        
        /// Total packet size including the header.
        var totalPacketLength: Int {
            Int(PacketHeader.size + contentSize)
        }
        
        /// Starting offset of the content.
        var contentOffset: Int {
            Int(PacketHeader.size)
        }

        static let size: UInt32 = 5

        // MARK: - Initialization
        
        init(code: UInt8, contentSize: UInt32) {
            self.code = code
            self.contentSize = contentSize
        }

        init(data: Data) throws {
            guard data.count >= PacketHeader.size else {
                throw PacketParsingError.notEnoughData
            }
            self.code = data[data.startIndex]
            self.contentSize = UInt32(data.from(1, size: 4))
        }
        
    }
    
    // MARK: - ConnectionState
    
    /// State of the connection.
    /// - `idle`: waiting for connect.
    /// - `connecting`: connection in progress.
    /// - `connected`: connected to the endpoint.
    public enum ConnectionState: CustomStringConvertible {
        case idle
        case connecting
        case connected
        
        public var description: String {
            switch self {
            case .idle:
                return "idle"
            case .connecting:
                return "connecting"
            case .connected:
                return "connected"
            }
        }
    }
    
}
