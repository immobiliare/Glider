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

import XCTest
@testable import Glider

final class RemoteTransportTests: XCTestCase, RemoteTransportServerDelegate, RemoteTransportDelegate {
    
    // MARK: - Private Properties
    
    private var server: RemoteTransportServer?
    private let serviceType = "_mylogger._tcp"
    private let serverName = "MyViewer"
    
    private var messageTimer: Timer?
    private var exp: XCTestExpectation?
    
    // MARK: - Tests
    
    func test_remoteTransport() async throws {
        
        exp = expectation(description: "")
        
        // Create a remote transport
        let remoteTransport = try RemoteTransport(serviceType: self.serviceType, delegate: self, {
            $0.autoConnectServerName = self.serverName
        })

        // Create logger.
        let log = Log {
            $0.transports = [
                remoteTransport
            ]
        }
                
        // Periodically send messages.
        messageTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            log.info?.write(msg: "Ciao")
        }
                
        // Create a server
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            do {
                self.server = RemoteTransportServer(serviceName: self.serverName, serviceType: self.serviceType, delegate: self)
                try self.server?.start()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        
        wait(for: [exp!], timeout: 60)

    }
    
    // MARK: - RemoteTransportDelegate
    
    func remoteTransport(_ transport: RemoteTransport, errorOccurred error: GliderError) {
        
    }
    
    func remoteTransport(_ transport: RemoteTransport, connectionStateDidChange newState: RemoteTransport.ConnectionState) {
        
    }
    
    func remoteTransport(_ transport: RemoteTransport, willStartConnectionTo endpoint: NWEndpoint) {
        
    }
    
    func remoteTransport(_ transport: RemoteTransport, connection: RemoteTransport.Connection, didChangeState newState: NWConnection.State) {
        
    }
    
    func remoteTransport(_ transport: RemoteTransport, willHandshakeWithConnection connection: RemoteTransport.Connection) {
        
    }
    
    func remoteTransport(_ transport: RemoteTransport, connection: RemoteTransport.Connection, error: GliderError) {
        
    }
    
    func remoteTrasnport(_ transport: RemoteTransport, connection: RemoteTransport.Connection, invalidMessageReceived data: Data, error: Error) {
        
    }
    
    func remoteTrasnport(_ transport: RemoteTransport, connection: RemoteTransport.Connection, failedToSendPacket packet: RemoteTransportPacket, error: Error) {
        
    }
    
    func remoteTrasnport(_ transport: RemoteTransport, connection: RemoteTransport.Connection, failedToDecodingPacketData data: Data, error: Error) {
        
    }
    
    // MARK: - RemoteTransportServerDelegate
    
    func remoteTransportServer(_ server: RemoteTransportServer,
                               willStartPublishingService serviceName: String) {
        print("RemoteTransportServer will start publishing \(serviceName)...")
    }
    
    func remoteTransportServer(_ server: RemoteTransportServer,
                               didChangeState newState: NWListener.State) {
        print("RemoteTransportServer state did change to \(newState.description)")
    }
    
    func remoteTransportServer(_ server: RemoteTransportServer,
                               didReceiveNewConnection connection: NWConnection) {
        print("RemoteTransportServer did receive new connection \(connection)")
    }
    
    func remoteTransportServer(_ server: RemoteTransportServer,
                               connection: RemoteTransport.Connection,
                               didChangeState newState: NWConnection.State) {
        
    }
    
    func remoteTransportServer(_ server: RemoteTransportServer,
                               client: RemoteTransportServer.Client,
                               didReceiveEvent event: Event) {
        print("Event received: \(event.message)")
    }
    
    func remoteTransportServer(_ server: RemoteTransportServer,
                               didConnectedClient client: RemoteTransportServer.Client) {
        print("RemoteTransportServer client connected!")
    }

}
