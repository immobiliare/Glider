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

extension RemoteTransportServer {
    
    /// Identify a client connected to the server.
    public final class Client: Identifiable {
        
        // MARK: - Public Properties
        
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
                self?.connection?.sendEmptyPacket(withCode: .ping)
            }
        }
        
        deinit {
            pingTimer?.invalidate()
        }
        
        // MARK: - Public Functions
        
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
                connection?.sendEmptyPacket(withCode: (isPaused ? .pause : .resume))
            }
        }
        
        internal func didConnectExistingClient() {
            isConnected = true
            sendConnectionStatus()
        }
        
        private func sendConnectionStatus() {
            didFailToUpdateStatus = false
            let isPaused = self.isPaused
            
            connection?.sendEmptyPacket(withCode: (isPaused ? .pause : .resume), { [weak self] error in
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
