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

public protocol RemoteTransportDelegate: AnyObject {
 
    // MARK: - General
    
    func remoteTransport(_ transport: RemoteTransport, errorOccurred error: GliderError)
    
    func remoteTransport(_ transport: RemoteTransport, connectionStateDidChange newState: RemoteTransport.ConnectionState)
    
    // MARK: - Connection
    
    func remoteTransport(_ transport: RemoteTransport, willStartConnectionTo endpoint: NWEndpoint)
    
    func remoteTransport(_ transport: RemoteTransport, connection: RemoteTransport.Connection, didChangeState newState: NWConnection.State)
    
    func remoteTransport(_ transport: RemoteTransport, willHandshakeWithConnection connection: RemoteTransport.Connection)
    
    func remoteTransport(_ transport: RemoteTransport, connection: RemoteTransport.Connection, error: GliderError)
    
    func remoteTrasnport(_ transport: RemoteTransport, connection: RemoteTransport.Connection, invalidMessageReceived data: Data, error: Error)
    
    func remoteTrasnport(_ transport: RemoteTransport, connection: RemoteTransport.Connection, failedToSendPacket packet: RemoteTransportPacket, error: Error)
    
    func remoteTrasnport(_ transport: RemoteTransport, connection: RemoteTransport.Connection, failedToDecodingPacketData data: Data, error: Error)

    
}

public protocol RemoteTransportConnectionDelegate: AnyObject {
    
    func connection(_ connection: RemoteTransport.Connection, didChangeState newState: NWConnection.State)
    func connection(_ connection: RemoteTransport.Connection, didReceiveEvent event: RemoteTransport.Connection.Event)

    func connection(_ connection: RemoteTransport.Connection, failedToSendPacket packet: RemoteTransportPacket, error: Error)
    func connection(_ connection: RemoteTransport.Connection, failedToDecodingPacketData data: Data, error: Error)

    
}
