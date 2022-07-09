//
//  File.swift
//  
//
//  Created by Daniele Margutti on 09/07/22.
//

import Foundation
import Network

//@available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
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
    
}

public protocol RemoteTransportConnectionDelegate: AnyObject {
    
    func connection(_ connection: RemoteTransport.Connection, didChangeState newState: NWConnection.State)
    func connection(_ connection: RemoteTransport.Connection, didReceiveEvent event: RemoteTransport.Connection.Event)

    func connection(_ connection: RemoteTransport.Connection, failedToProcessingPacket data: Data, error: Error)

    func connection(_ connection: RemoteTransport.Connection, failedToEncodingObject: Any, error: Error)

    func connection(_ connection: RemoteTransport.Connection, failedToSendData data: Data, error: NWError)
    
}
