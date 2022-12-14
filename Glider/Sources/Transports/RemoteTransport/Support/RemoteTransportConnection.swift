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
#if canImport(Network)
import Network

@available(macOS 10.15, iOS 13.0, tvOS 13.0, macCatalyst 13.0, *)
extension RemoteTransport {
    
    /// Identify a connection server which will receive messages from the transport.
    public final class Connection {
        
        // MARK: - Private Properties
        
        /// Internal buffer.
        private var buffer = Data()
        
        /// Connection used.
        private let connection: NWConnection
        
        // MARK: - Public Properties
        
        /// Delegate method
        internal weak var delegate: RemoteTransportConnectionDelegate?
        
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
        
        // MARK: - Send Data
        
        /// Send an empty packet with the following control code.
        ///
        /// - Parameters:
        ///   - code: control code.
        ///   - completion: completion callback.
        public func sendPacketCode(_ code: PacketCode, _ completion: ((NWError?) -> Void)? = nil) {
            let packet = RemoteTransport.PacketEmpty(code: code)
            sendPacket(packet, completion)
        }
        
        /// Send event to the remote side.
        ///
        /// - Parameters:
        ///   - event: event to send.
        ///   - completion: completion callback.
        public func sendEvent(_ event: Glider.Event, _ completion: ((NWError?) -> Void)? = nil) {
            let packet = PacketEvent(event: event)
            sendPacket(packet, completion)
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
        
        // MARK: - Private Functions

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

// MARK: - RemoteTransportConnectionDelegate

/// This is the internal protocol used to exchange messages between the `RemoteTransport`
/// and their `Connection` instances.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, macCatalyst 13.0, *)
internal protocol RemoteTransportConnectionDelegate: AnyObject {
    
    /// Triggered when a connection did change its state.
    ///
    /// - Parameters:
    ///   - connection: connection destination.
    ///   - newState: new state.
    func connection(_ connection: RemoteTransport.Connection,
                    didChangeState newState: NWConnection.State)
    
    /// Triggered when a new event has been fired from a connection instance.
    ///
    /// - Parameters:
    ///   - connection: connection destination.
    ///   - event: event.
    func connection(_ connection: RemoteTransport.Connection,
                    didReceiveEvent event: RemoteTransport.RemoteEvent)
    
    /// Triggered when a packet send operation di fail to a child connection.
    ///
    /// - Parameters:
    ///   - connection: connection destination.
    ///   - packet: packet to send.
    ///   - error: error occurred.
    func connection(_ connection: RemoteTransport.Connection,
                    failedToSendPacket packet: RemoteTransportPacket,
                    error: Error)
    
    /// Triggered when a packet encoding operation did fail with error.
    ///
    /// - Parameters:
    ///   - connection: connection destination.
    ///   - data: data to send.
    ///   - error: error occurred.
    func connection(_ connection: RemoteTransport.Connection,
                    failedToDecodingPacketData data: Data,
                    error: Error)

}
#endif
