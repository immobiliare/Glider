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

public protocol RemoteTransportServerDelegate: AnyObject {
    
    func remoteTransportServer(_ server: RemoteTransportServer,
                               willStartPublishingService serviceName: String)
    
    func remoteTransportServer(_ server: RemoteTransportServer,
                               didChangeState newState: NWListener.State)

    func remoteTransportServer(_ server: RemoteTransportServer,
                               didReceiveNewConnection connection: NWConnection)
    
    func remoteTransportServer(_ server: RemoteTransportServer,
                               connection: RemoteTransport.Connection, didChangeState newState: NWConnection.State)

    func remoteTransportServer(_ server: RemoteTransportServer,
                               client: RemoteTransportServer.Client,
                               didReceiveEvent event: Glider.Event)

    func remoteTransportServer(_ server: RemoteTransportServer,
                               didConnectedClient client: RemoteTransportServer.Client)

}
