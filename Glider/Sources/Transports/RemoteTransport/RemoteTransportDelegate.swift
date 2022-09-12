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

/// You can implement the following method in order to receive important information
/// about the status and the events of the `RemoteTransport` instance during its lifecycle.
public protocol RemoteTransportDelegate: AnyObject {
 
    // MARK: - General
    
    /// Triggered when an error has occurred.
    ///
    /// - Parameters:
    ///   - transport: transport.
    ///   - error: error.
    func remoteTransport(_ transport: RemoteTransport,
                         errorOccurred error: GliderError)
    
    /// Triggered when cnnection of the transport did change.
    ///
    /// - Parameters:
    ///   - transport: transport.
    ///   - newState: new state.
    func remoteTransport(_ transport: RemoteTransport,
                         connectionStateDidChange newState: RemoteTransport.ConnectionState)
    
    /// Triggered when a new connection is in progress.
    ///
    /// - Parameters:
    ///   - transport: transport.
    ///   - endpoint: endpoint.
    func remoteTransport(_ transport: RemoteTransport,
                         willStartConnectionTo endpoint: NWEndpoint)
    
    /// Triggered when a connection client state did change.
    ///
    /// - Parameters:
    ///   - transport: transport.
    ///   - connection: connection target.
    ///   - newState: new state.
    func remoteTransport(_ transport: RemoteTransport,
                         connection: RemoteTransport.Connection,
                         didChangeState newState: NWConnection.State)
    
    /// Triggered when a new connection is establishing with the initial handshake.
    ///
    /// - Parameters:
    ///   - transport: transport.
    ///   - connection: connection.
    func remoteTransport(_ transport: RemoteTransport,
                         willHandshakeWithConnection connection: RemoteTransport.Connection)
    
    /// Triggered when a connection did fail with error.
    ///
    /// - Parameters:
    ///   - transport: transport.
    ///   - connection: connection.
    ///   - error: error.
    func remoteTransport(_ transport: RemoteTransport,
                         connection: RemoteTransport.Connection,
                         error: GliderError)
    
    /// Triggered when an unknown data payload has been received.
    ///
    /// - Parameters:
    ///   - transport: transport.
    ///   - connection: connection.
    ///   - data: data raw.
    ///   - error: error.
    func remoteTrasnport(_ transport: RemoteTransport,
                         connection: RemoteTransport.Connection,
                         invalidMessageReceived data: Data, error: Error)
    
    /// Triggered when a send method fail with error.
    ///
    /// - Parameters:
    ///   - transport: transport.
    ///   - connection: connection destination.
    ///   - packet: packet to send.
    ///   - error: error.
    func remoteTrasnport(_ transport: RemoteTransport,
                         connection: RemoteTransport.Connection,
                         failedToSendPacket packet: RemoteTransportPacket, error: Error)
    
    /// Triggered when encoding of payload did fails.
    ///
    /// - Parameters:
    ///   - transport: transport.
    ///   - connection: connection destination.
    ///   - data: data.
    ///   - error: error.
    func remoteTrasnport(_ transport: RemoteTransport,
                         connection: RemoteTransport.Connection,
                         failedToDecodingPacketData data: Data, error: Error)

}
#endif
