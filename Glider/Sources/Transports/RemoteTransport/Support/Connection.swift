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
import Network

extension RemoteTransport {
    
    public final class Connection {
        
        // MARK: - Private Properties
        
        /// Internal buffer.
        private var buffer = Data()
        
        /// Connection used.
        private let connection: NWConnection
        
        // MARK: - Public Properties
        
        /// Delegate method
        public weak var delegate: RemoteTransportConnectionDelegate?
        
        // MARK: - Initialization
        
        /// Initialize with connection.
        ///
        /// - Parameter connection: connection.
        public init(_ connection: NWConnection) {
            self.connection = connection
        }
        
        /// Initialize with a connection endpoint.
        ///
        /// - Parameter endpoint: endpoint.
        public convenience init(endpoint: NWEndpoint) {
            self.init(NWConnection(to: endpoint, using: .tcp))
        }
        
        // MARK: - Manage Connection
        
        /// Open connection.
        ///
        /// - Parameter queue: queue of the connection.
        public func start(on queue: DispatchQueue) {
            connection.stateUpdateHandler = { [weak self] in
                guard let self = self else { return }
                
                self.delegate?.connection(self, didChangeState: $0)
            }
            
            receive()
            connection.start(queue: queue)
        }
        
        /// Close connection.
        public func cancel() {
            connection.cancel()
        }
        
        // MARK: - Send Packets
        
        public func sendEmptyPacket(withCode code: PacketCode, _ completion: ((NWError?) -> Void)? = nil) {
            let packet = RemoteTransport.PacketEmpty(code: code)
            sendPacket(packet, completion)
        }
        
        public func sendEvent(_ event: Glider.Event, _ completion: ((NWError?) -> Void)? = nil) {
            let packetEvent = PacketEvent(event: event)
            sendPacket(packetEvent)
        }
        
        /// Send a packet to the remote connection.
        ///
        /// - Parameters:
        ///   - packet: packet to send.
        ///   - completion: completion handler.
        public func sendPacket(_ packet: RemoteTransportPacket, _ completion: ((NWError?) -> Void)? = nil) {
            do {
                let data = try encodePacket(packet: packet)
                connection.send(content: data, completion: .contentProcessed({ [weak self] error in
                    if let error = error {
                        self?.delegate?.connection(self!, failedToSendPacket: packet, error: error)
                    }
                }))
            } catch {
                delegate?.connection(self, failedToSendPacket: packet, error: GliderError(message: "Failed to encode packet"))
            }
        }
        
        // MARK: - Sending Events

        private func receive() {
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65535) { [weak self] data, _, isCompleted, error in
                guard let self = self else { return }
                if let data = data, !data.isEmpty {
                    self.process(data: data)
                }
                
                if isCompleted {
                    self.delegate?.connection(self, didReceiveEvent: .completed)
                } else if let error = error {
                    self.delegate?.connection(self, didReceiveEvent: .error(error))
                } else {
                    self.receive()
                }
            }
        }
        
        private func process(data freshData: Data) {
            guard !freshData.isEmpty else { return }

            var freshData = freshData
            if buffer.isEmpty {
                while let (packet, size) = decodeData(freshData) {
                    self.delegate?.connection(self, didReceiveEvent: .packet(packet))
                    if size == freshData.count {
                        return // No no processing needed
                    }
                    freshData.removeFirst(size)
                }
            }

            if !freshData.isEmpty {
                buffer.append(freshData)
                while let (packet, size) = decodeData(buffer) {
                    self.delegate?.connection(self, didReceiveEvent: .packet(packet))
                    buffer.removeFirst(size)
                }
                if buffer.count == 0 {
                    buffer = Data()
                }
            }
        }
        
        // MARK: - Encoding/Decoding
        
        /// Decoding a packet.
        ///
        /// - Parameter data: data.
        /// - Returns: `(RawPacket, Int)?`
        private func decodeData(_ data: Data) -> (RawPacket, Int)? {
            do {
                return try decodeRawPacketData(data)
            } catch {
                if case .notEnoughData? = error as? PacketParsingError {
                    return nil
                }
                
                delegate?.connection(self, failedToDecodingPacketData: data, error: error)
                return nil
            }
        }
        
        /// The following function generate a `Packet` from a raw data from server.
        ///
        /// - Parameter buffer: buffer.
        /// - Returns: `(Packet, Int)`
        private func decodeRawPacketData(_ buffer: Data) throws -> (RawPacket, Int)? {
            let header = try PacketHeader(data: buffer)
            guard buffer.count >= header.totalPacketLength else {
                throw PacketParsingError.notEnoughData
            }
            
            let body = buffer.from(header.contentOffset, size: Int(header.contentSize))
            let rawPacket = RawPacket(code: header.code, body: body)
            return (rawPacket, header.totalPacketLength)
        }
        
        /// Encode a packet ready to be sent to a connection.
        ///
        /// - Parameter packet: packet to encode.
        /// - Returns: `Data`
        private func encodePacket(packet: RemoteTransportPacket) throws -> Data {
            let body = try packet.encode()
            guard body.count < UInt32.max else {
                throw PacketParsingError.unsupportedContentSize
            }

            var data = Data()
            data.append(packet.code.rawValue)
            data.append(Data(UInt32(body.count)))
            data.append(body)
            return data
        }
        
    }
    
}

extension RemoteTransport.Connection {
    
    public enum Event {
        case packet(RawPacket)
        case error(Error)
        case completed
    }
    
    public struct RawPacket {
        public let code: UInt8
        public let body: Data
        
        public var readableCode: RemoteTransport.PacketCode? {
            .init(rawValue: code)
        }
    }
    
    /// Parsing errors.
    enum PacketParsingError: Error {
        case notEnoughData
        case unsupportedContentSize
    }
    
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
    
}


extension RemoteTransport {
    
    public enum ConnectionState: CustomStringConvertible {
        case idle
        case connecting
        case connected
        
        public var description: String {
            switch self {
            case .idle: return "idle"
            case .connecting: return "connecting"
            case .connected: return "connected"
            }
        }
    }
    
}
