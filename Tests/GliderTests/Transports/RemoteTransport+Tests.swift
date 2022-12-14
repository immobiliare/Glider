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

#if canImport(Network)
import Foundation
import Network

import XCTest
@testable import Glider

@available(iOS 13.0.0, tvOS 13.0, *)
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
        exp = expectation(description: "Waiting for receive messages")
        
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
        messageTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            if let event = log.info?.write(msg: "Hello \(self.sentEvents)", extra: ["idx": self.sentEvents]) {
                self.sendEvents.append(event)
                self.sentEvents += 1
                
                if self.sentEvents == self.countEvents {
                    self.messageTimer?.invalidate()
                    self.exp?.fulfill()
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

// MARK: - RemoteTransportReconnectClientTests

@available(iOS 13.0.0, tvOS 13.0, *)
final class RemoteTransportReconnectClientTests: RemoteTransportTests {
    
    private var connectionClosed = false
    private var remoteTransport: RemoteTransport?
    private var fulfilled = false
    
    override func test_remoteTransport() async throws {
        
    }

    func test_remoteTransportAutoClientReconnect() async throws {
        exp = expectation(description: "Waiting for reconnection test")
        
        // Create a remote transport
        remoteTransport = try RemoteTransport(serviceType: self.serviceType, delegate: nil, {
            $0.autoConnectServerName = self.serverName
            $0.autoRetryConnectInterval = 2
        })

        // Create logger.
        let log = Log {
            $0.transports = [
                remoteTransport!
            ]
        }
                
        // Periodically send messages.
        messageTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            log.info?.write(msg: "Hello \(self.sentEvents)", extra: ["idx": self.sentEvents])
            self.sentEvents += 1
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
        
        // Close connection for server.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.connectionClosed = true
            self.server?.clientsArray.first?.disconnect()
        }
        
        wait(for: [exp!], timeout: 60)
    }
    
    override func remoteTransportServer(_ server: RemoteTransportServer,
                               client: RemoteTransportServer.Client,
                               didReceiveEvent event: Event) {
        print("Event received: \(event.message)")

        if connectionClosed == true  && fulfilled == false{
            server.stop()
            fulfilled = true
            exp?.fulfill()
        }
    }
    
    
    override func remoteTransportServer(_ server: RemoteTransportServer,
                               didChangeState newState: NWListener.State) {
        print("RemoteTransportServer state did change to \(newState.description)")
    }
    
}

// MARK: - RemoteTransportReconnectServerTests

@available(iOS 13.0.0, tvOS 13.0, *)
final class RemoteTransportReconnectServerTests: RemoteTransportTests {
    
    private var connectionClosed = false
    private var remoteTransport: RemoteTransport?
    private var fulfilled = false
    
    override func test_remoteTransport() async throws {
        
    }

    func test_remoteTransportAutoServerReconnect() async throws {
        exp = expectation(description: "Waiting for reconnection test")
        
        // Create a remote transport
        remoteTransport = try RemoteTransport(serviceType: self.serviceType, delegate: nil, {
            $0.autoConnectServerName = self.serverName
            $0.autoRetryConnectInterval = 2
        })

        // Create logger.
        let log = Log {
            $0.transports = [
                remoteTransport!
            ]
        }
                
        // Periodically send messages.
        messageTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            log.info?.write(msg: "Hello \(self.sentEvents)", extra: ["idx": self.sentEvents])
            self.sentEvents += 1
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
        
        // Close connection for server.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.connectionClosed = true
            self.remoteTransport?.stop()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            self.remoteTransport?.start()
        }
        
        wait(for: [exp!], timeout: 60)
    }
    
    override func remoteTransportServer(_ server: RemoteTransportServer,
                               client: RemoteTransportServer.Client,
                               didReceiveEvent event: Event) {
        print("Event received: \(event.message)")
        
        if connectionClosed == true  && fulfilled == false{
            server.stop()
            fulfilled = true
            exp?.fulfill()
        }
    }
    
    override func remoteTransportServer(_ server: RemoteTransportServer,
                               didChangeState newState: NWListener.State) {
        print("RemoteTransportServer state did change to \(newState.description)")
    }
    
}
#endif
