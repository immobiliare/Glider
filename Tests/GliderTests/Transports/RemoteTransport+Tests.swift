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

class RemoteTransportTests: XCTestCase, RemoteTransportServerDelegate {
    
    // MARK: - Private Properties
    
    open var server: RemoteTransportServer?
    public let serviceType = "_mylogger._tcp"
    public let serverName = "MyViewer"
    
    open var messageTimer: Timer?
    open var exp: XCTestExpectation?
    open var sendEvents = [Glider.Event]()
    open var receivedEvents = [Glider.Event]()

    open var countEvents = 10
    open var sentEvents = 0

    // MARK: - Tests
    
    /// The following test validate the auto connection and data receive.
    func test_remoteTransport() async throws {
        
        exp = expectation(description: "")
        
        // Create a remote transport
        let remoteTransport = try RemoteTransport(serviceType: self.serviceType, delegate: nil, {
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
            if let event = log.info?.write(msg: "Hello \(self.sentEvents)", extra: ["idx": self.sentEvents]) {
                self.sendEvents.append(event)
                self.sentEvents += 1
                
                if self.sentEvents == self.countEvents {
                    self.messageTimer?.invalidate()
                }
            }
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
        
        receivedEvents.append(event)
        
        if receivedEvents.count == countEvents {
            XCTAssertEqual(receivedEvents, sendEvents)
            exp?.fulfill()
        }
    }
    
    func remoteTransportServer(_ server: RemoteTransportServer,
                               didConnectedClient client: RemoteTransportServer.Client) {
        print("RemoteTransportServer client connected!")
    }

}

// MARK: - RemoteTransportReconnectTests

final class RemoteTransportReconnectTests: RemoteTransportTests {
    
    private var connectionClosed = false

    func test_remoteTransportAutoReconnect() async throws {
        exp = expectation(description: "")
        
        // Create a remote transport
        let remoteTransport = try RemoteTransport(serviceType: self.serviceType, delegate: nil, {
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
            if let event = log.info?.write(msg: "Hello \(self.sentEvents)", extra: ["idx": self.sentEvents]) {
                self.sendEvents.append(event)
                self.sentEvents += 1
            }
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.server?.stop()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            try? self.server?.start()
        }
        
        wait(for: [exp!], timeout: 60)
    }
    
    override func remoteTransportServer(_ server: RemoteTransportServer,
                               client: RemoteTransportServer.Client,
                               didReceiveEvent event: Event) {
        print("Event received: \(event.message)")

        if connectionClosed == true {
            exp?.fulfill()
        }
    }
    
    
    override func remoteTransportServer(_ server: RemoteTransportServer,
                               didChangeState newState: NWListener.State) {
        if newState == .cancelled {
            print("RemoteTransportServer closed!")
            connectionClosed = true
        } else {
            print("RemoteTransportServer state did change to \(newState.description)")
        }
    }
    
}
