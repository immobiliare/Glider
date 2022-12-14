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

@available(macOS 10.15, iOS 13.0, tvOS 13.0, macCatalyst 13.0, *)
extension RemoteTransportServer {
    
    /// Identify a client connected to the server.
    public final class Client: Identifiable {
        
        // MARK: - Public Properties
        
        public internal(set) var clientId: ClientId?
        
        /// Client info.
        public private(set) var info: RemoteTransport.PacketHello.Info
        
        /// Parent connection.
        public internal(set) var connection: RemoteTransport.Connection?
        
        /// Is the client connected.
        public private(set) var isConnected = false
        
        /// Is client paused.
        public private(set) var isPaused = true

        // MARK: - Private Properties
        
        /// Disconnection action item.
        private var timeoutDisconnectItem: DispatchWorkItem?
        
        /// Sending information failed.
        private var didFailToUpdateStatus = false
        
        /// Timer used to periodically ping the other side.
        private var pingTimer: Timer?
        
        // MARK: - Initialization
        
        /// Initialize a new client from an hello request received.
        ///
        /// - Parameter request: request.
        internal init(request: RemoteTransport.PacketHello) {
            self.info = request.info
            
            pingTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self]_ in
                self?.connection?.sendPacketCode(.ping)
            }
        }
        
        deinit {
            pingTimer?.invalidate()
        }
        
        // MARK: - Public Functions
        
        public func disconnect() {
            isConnected = false
            connection?.cancel()
        }
        
        /// Pause client.
        public func pause() {
            guard isPaused == false else { return }
            
            isPaused = true
            sendConnectionStatus()
        }
        
        /// Resume client.
        public func resume() {
            guard isPaused == true else { return }
            
            isPaused = false
            sendConnectionStatus()
        }

        // MARK: - Internal Functions
        
        /// Called when a ping request has been received.
        /// It will reply to the request.
        internal func didReceivePing() {
            if !isConnected {
                isConnected = true
            }
            scheduleAutomaticDisconnect()
            
            if didFailToUpdateStatus {
                didFailToUpdateStatus = false
                connection?.sendPacketCode((isPaused ? .pause : .resume))
            }
        }
        
        internal func didConnectExistingClient() {
            isConnected = true
            sendConnectionStatus()
        }
        
        private func sendConnectionStatus() {
            didFailToUpdateStatus = false
            let isPaused = self.isPaused
            
            connection?.sendPacketCode((isPaused ? .pause : .resume), { [weak self] error in
                if error != nil {
                    self?.didFailToUpdateStatus = true
                }
            })
        }
        
        private func scheduleAutomaticDisconnect() {
            timeoutDisconnectItem?.cancel()
            
            let item = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.isConnected = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(6), execute: item)
            timeoutDisconnectItem = item
        }
        
    }
    
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, macCatalyst 13.0, *)
extension RemoteTransportServer {
    
    public struct ClientId: Hashable {
        public let raw: String
                
        internal init(request: RemoteTransport.PacketHello) {
            self.raw = (request.info.deviceId?.uuidString ?? "") +
                        (request.info.appInfo.bundleIdentifier ?? "–")
        }
        
        init(_ id: String) {
            self.raw = id
        }
    }
    
}
