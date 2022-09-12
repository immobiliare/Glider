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

/// This is the delegate protocol which allows you to read important data about
/// the lifecycle of `RemoteTransportServer`, a typical destination for
/// `RemoteTransport` protocol which you will implement in your client.
public protocol RemoteTransportServerDelegate: AnyObject {
    
    /// Triggered when server did start publishing its service over the network.
    ///
    /// - Parameters:
    ///   - server: server.
    ///   - serviceName: service name.
    func remoteTransportServer(_ server: RemoteTransportServer,
                               willStartPublishingService serviceName: String)
    
    /// Triggered when server state did change.
    ///
    /// - Parameters:
    ///   - server: server.
    ///   - newState: new state.
    func remoteTransportServer(_ server: RemoteTransportServer,
                               didChangeState newState: NWListener.State)
    
    /// Triggered when server did receive a new connection from a `RemoteTransport` instance.
    ///
    /// - Parameters:
    ///   - server: server.
    ///   - connection: connection client.
    func remoteTransportServer(_ server: RemoteTransportServer,
                               didReceiveNewConnection connection: NWConnection)
    
    /// Triggered when a new connected client did change its tate.
    ///
    /// - Parameters:
    ///   - server: server.
    ///   - connection: connection client.
    ///   - newState: new state.
    func remoteTransportServer(_ server: RemoteTransportServer,
                               connection: RemoteTransport.Connection, didChangeState newState: NWConnection.State)
    
    /// Triggered when server receive a new log event from a client.
    ///
    /// - Parameters:
    ///   - server: server.
    ///   - client: client origin.
    ///   - event: event received.
    func remoteTransportServer(_ server: RemoteTransportServer,
                               client: RemoteTransportServer.Client,
                               didReceiveEvent event: Glider.Event)
    
    /// Triggered when server did establish a new connection with a client.
    ///
    /// - Parameters:
    ///   - server: server.
    ///   - client: connected client.
    func remoteTransportServer(_ server: RemoteTransportServer,
                               didConnectedClient client: RemoteTransportServer.Client)

}
#endif
