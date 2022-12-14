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

/// Defines a delegate for a websocket connection.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, macCatalyst 13.0, *)
public protocol WebSocketClientDelegate: AnyObject {
    
    /// Tells the delegate that the WebSocket did connect successfully.
    /// - Parameter connection: The active `WebSocketConnection`.
    func webSocketDidConnect(connection: WebSocketClient)

    /// Tells the delegate that the WebSocket did disconnect.
    /// - Parameters:
    ///   - connection: The `WebSocketConnection` that disconnected.
    ///   - closeCode: A `NWProtocolWebSocket.CloseCode` describing how the connection closed.
    ///   - reason: Optional extra information explaining the disconnection. (Formatted as UTF-8 encoded `Data`).
    func webSocketDidDisconnect(connection: WebSocketClient,
                                closeCode: NWProtocolWebSocket.CloseCode,
                                reason: Data?)

    /// Tells the delegate that the WebSocket connection viability has changed.
    ///
    /// An example scenario of when this method would be called is a Wi-Fi connection being lost due to a device
    /// moving out of signal range, and then the method would be called again once the device moved back in range.
    /// - Parameters:
    ///   - connection: The `WebSocketConnection` whose viability has changed.
    ///   - isViable: A `Bool` indicating if the connection is viable or not.
    func webSocketViabilityDidChange(connection: WebSocketClient,
                                     isViable: Bool)

    /// Tells the delegate that the WebSocket has attempted a migration based on a better network path becoming available.
    ///
    /// An example of when this method would be called is if a device is using a cellular connection, and a Wi-Fi connection
    /// becomes available. This method will also be called if a device loses a Wi-Fi connection, and a cellular connection is available.
    /// - Parameter result: A `Result` containing the `WebSocketConnection` if the migration was successful, or a
    /// `NWError` if the migration failed for some reason.
    func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketClient, NWError>)

    /// Tells the delegate that the WebSocket received an error.
    ///
    /// An error received by a WebSocket is not necessarily fatal.
    /// - Parameters:
    ///   - connection: The `WebSocketConnection` that received an error.
    ///   - error: The `NWError` that was received.
    func webSocketDidReceiveError(connection: WebSocketClient,
                                  error: NWError)

    /// Tells the delegate that the WebSocket received a 'pong' from the server.
    /// - Parameter connection: The active `WebSocketConnection`.
    func webSocketDidReceivePong(connection: WebSocketClient)

    /// Tells the delegate that the WebSocket received a `String` message.
    /// - Parameters:
    ///   - connection: The active `WebSocketConnection`.
    ///   - string: The UTF-8 formatted `String` that was received.
    func webSocketDidReceiveMessage(connection: WebSocketClient,
                                    string: String)

    /// Tells the delegate that the WebSocket received a binary `Data` message.
    /// - Parameters:
    ///   - connection: The active `WebSocketConnection`.
    ///   - data: The `Data` that was received.
    func webSocketDidReceiveMessage(connection: WebSocketClient,
                                    data: Data)
    
}
#endif
