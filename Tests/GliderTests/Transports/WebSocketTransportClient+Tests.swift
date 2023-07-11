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

#if os(iOS) || os(tvOS)
import Foundation
import Network
import CoreGraphics
import UIKit


import XCTest
@testable import Glider
import CloudKit

@available(iOS 13.0.0, tvOS 13.0, *)
class WebSocketTransportClientTests: XCTestCase, WebSocketServerDelegate, WebSocketTransportClientDelegate {
    
    private var server: WebSocketServer?
    private var expServerReceive: XCTestExpectation?
    private var receivedEvents = [Event]()
    private var eventsToGenerate = 30
    private var serverPort: UInt16 = 1011

    func tests_webSocketTransport() throws {
        // Create WebSocket server
        print("Starting WebSocket Server on port \(serverPort)")
        server?.stop()
        server = WebSocketServer(port: serverPort)
        server?.delegate = self
        try server?.start()
        
        // Prepare formatter
        let format = FieldsFormatter(fields: [
            .message({
                $0.truncate = .head(length: 10)
            }),
        ])

        let transport = try WebSocketTransportClient(url: "ws://localhost:1011", delegate: self) {
            $0.connectAutomatically = true
            $0.formatters = [format]
            $0.dataType = .event(encoder: JSONEncoder())
        }
                
        let log = Log {
            $0.level = .trace
            $0.transports = [transport]
        }
        
        // Generate events
        var generatedEvents = [Event]()
        for i in 0..<eventsToGenerate {
            let color = UIColor(hue: CGFloat(drand48()), saturation: 1, brightness: 1, alpha: 1)
            let size = CGSize(width: CGFloat(Float.random(in: 0..<4000)), height: CGFloat(Float.random(in: 0..<4000)))
            let image = UIImage.getImageWithColor(color: color, size: size)
            
            let e = Event(message: "Message \(i)", object: image)
            generatedEvents.append(e)
        }
        
        expServerReceive = expectation(description: "Expecting events to be received from server...")

        print("Will send \(generatedEvents.count) events...")
        for event in generatedEvents {
            var e = event
            print("  Sending event \(e.id)...")
            log.info?.write(event: &e)
        }
                
        wait(for: [expServerReceive!], timeout: 20)
        
        XCTAssertEqual(receivedEvents.count, generatedEvents.count)
        XCTAssertEqual(receivedEvents, generatedEvents)

        transport.disconnect(closeCode: .protocolCode(.normalClosure))
        server?.stop()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        
        server?.stop()
    }
    
    // MARK: - WebSocketTransportDelegate
    
    func webSocketTransportConnecting(_ transport: WebSocketTransportClient) {
        print("Connecting to websocket server...")
    }
    
    func webSocketTransport(_ transport: WebSocketTransportClient, didChangeState newState: NWConnection.State) {

    }
    
    func webSocketTransport(_ transport: WebSocketTransportClient, didConnect url: URL) {

    }
    
    func webSocketTransport(_ transport: WebSocketTransportClient, didDisconnectedWithCode code: NWProtocolWebSocket.CloseCode, reason: String?) {
        
    }
    
    func webSocketTransport(_ transport: WebSocketTransportClient, didReceiveError error: Error?) {
        
    }
    
    func webSocketTransportDidReceivePoing(_ transport: WebSocketTransportClient) {
        
    }
    
    func webSocketTransport(_ transport: WebSocketTransportClient, didReceiveData data: SerializableData?) {
        
    }
    
    func webSocketTransport(_ transport: WebSocketTransportClient, isViable: Bool) {

    }
    
    func webSocketTransport(_ transport: WebSocketTransportClient, didSendPayload payload: WebSocketTransportClient.Payload, error: Error?) {
        
    }
    
    
    // MARK: - WebSocketServerDelegate
    
    func webSocketServer(_ server: WebSocketServer, didChangeState state: NWListener.State) {
        print("[Server] state change state to \(state)")
    }
    
    func webSocketServer(_ server: WebSocketServer, didStopConnection connection: WebSocketPeer) {
        print("[Server] Connection stopped")
    }
    
    func webSocketServer(_ server: WebSocketServer, didStopServerWithError error: NWError?) {
        print("[Server] Stopped with error: \(error?.localizedDescription ?? "<none>")")
    }
    
    func webSocketServer(_ server: WebSocketServer, didOpenConnection client: WebSocketPeer) {
        print("[Server] Connection opened!")
    }
    
    func webSocketServer(_ server: WebSocketServer, peer: WebSocketPeer, didChangeState state: NWConnection.State) {
        print("[Server] Peer change state to \(state)")
    }
    
    func webSocketServer(_ server: WebSocketServer, peer: WebSocketPeer, didReceiveData data: Data) {
        do {
            let event = try JSONDecoder().decode(Event.self, from: data)
            receivedEvents.append(event)
            
            print("  [Server] Received new event: \(event.id)")
            if receivedEvents.count == eventsToGenerate {
                expServerReceive?.fulfill()
            }
        } catch {
            XCTFail("Failed to decode an event")
        }
    }
    
    func webSocketServer(_ server: WebSocketServer, peer: WebSocketPeer, didReceiveString string: String) {

    }
}

// MARK: - Helper

extension UIImage {

    class func getImageWithColor(color: UIColor, size: CGSize) -> UIImage
    {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: size.width, height: size.height))
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }


}
#endif
