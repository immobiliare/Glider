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

/// The `RemoteTransport` is used to send log in a custom binary format to a LAN/WAN destination.
/// It uses Bonjour/ZeroConfig to found active server where tto send data.
///
/// Usually you should use a single instance of this transport for all of yours loggers.
/// In this case use the `RemoteTransport.shared` shortcut instead of creating a new one.
///
/// ## Important
/// Be sure to set the following keys in your app's `Info.plist`:
///
/// ```xml
/// <key>NSLocalNetworkUsageDescription</key>
///    <string>Network usage required for debugging activities</string>
/// <key>NSBonjourServices</key>
/// <array>
///    <string>_glider._tcp</string>
/// </array>
/// ```
/// 
public class RemoteTransport: Transport {
    
    // MARK: - Public Properties
    
    /// Configuration object.
    public let configuration: Configuration
 
    /// Delegate object to receive messages.
    public weak var delegate: RemoteTransportDelegate?
        
    /// Is logging enabled?
    public var isEnabled: Bool {
        didSet {
            if isEnabled {
                /// Enables remote logging.
                /// The transport will start searching for available servers.
                queue?.async(execute: startBrowser)
            } else {
                /// Disables remote logging and disconnects from the server.
                queue?.async(execute: cancel)
            }
        }
    }
    
    /// Minimum accepted level for this transport. By default is `nil` which means
    /// no filter is made after the event is accepted by the parent log instance.
    public var minimumAcceptedLevel: Level?
    
    /// Dispatch queue. You should never change it once set.
    public var queue: DispatchQueue?
    
    // MARK: - Public Properties (Manage Connection)
    
    /// List of discovered servers.
    public private(set) var servers: Set<NWBrowser.Result> = []
    
    /// Currently selected server.
    private(set) public var selectedServer = ""
    
    /// Current state of the connection
    public private(set) var connectionState: ConnectionState = .idle {
        didSet {
            delegate?.remoteTransport(self, connectionStateDidChange: connectionState)
        }
    }
    
    // MARK: - Private Properties (Browsing Related)
    
    /// Is the connections started.
    private var isStarted = false
    
    /// Is logging service enabled.
    private var isLoggingPaused = true
    
    /// The browser discovery class.
    private var browser: NWBrowser?
    
    
    // MARK: - Private Properties (Connection Related)
    
    /// Connection used.
    private var connection: Connection?
    
    /// Connected server.
    private var connectedServer: NWBrowser.Result?
    
    private var connectionRetryItem: DispatchWorkItem?
    private var timeoutDisconnectItem: DispatchWorkItem?
    private var pingItem: DispatchWorkItem?

    private var buffer: [Glider.Event]? = []

    // MARK: - Initialization
    
    /// Initialize with configuration.
    ///
    /// - Parameter configuration: configuration.
    public init(configuration: Configuration, delegate: RemoteTransportDelegate? = nil) throws {
        self.configuration = configuration
        self.isEnabled = configuration.isEnabled
        self.queue = configuration.queue
        
        if isEnabled {
            queue?.async(execute: startBrowser)
        }

        // The buffer is used to cover the time between the app launch and the
        // iniitial (automatic) connection to the server.
        queue?.asyncAfter(deadline: .now() + .seconds(2)) { [weak self] in
            self?.buffer = nil
        }
    }
    
    public convenience init(serviceType: String = Configuration.defaultServiceType,
                            delegate: RemoteTransportDelegate? = nil,
                            _ builder: ((inout Configuration) -> Void)? = nil) throws {
        try self.init(configuration: Configuration(serviceType: serviceType, builder), delegate: delegate)
    }
    
    // MARK: - Public Functions
    
    /// Start browser.
    public func start() {
        isEnabled = true
    }
    
    /// Stop browser.
    public func stop() {
        isEnabled = false
    }
    
    public func record(event: Glider.Event) -> Bool {
        if isLoggingPaused {
            buffer?.append(event)
        } else {
            connection?.sendEvent(event)
        }
        return true
    }
    
    // MARK: - Private Functions (Browsing)
    
    /// Cancel the discovery of the network services.
    private func cancelBrowser() {
        browser?.cancel()
        browser = nil
    }
    
    /// Start a new discovery for remote endpoints.
    private func startBrowser() {
        guard let queue = queue, !isStarted else { return }
        
        isStarted = true

        let browser = NWBrowser(for: .bonjour(type: configuration.serviceType, domain: "local"), using: .tcp)

        // Listen when state did change
        browser.stateUpdateHandler = { [weak self] newState in
            guard let self = self, self.isEnabled else { return }

            if case .failed = newState {
                // for failure schedule a new retry after delay
                self.scheduleBrowserRetry()
            }
        }
        
        // Listen for new discovered endpoints
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            guard let self = self, self.isEnabled else { return }

            self.servers = results
            self.connectAutomaticallyIfNeeded()
        }

        // Start browsing and ask for updates on the main queue.
        browser.start(queue: queue)

        self.browser = browser
    }
    
    /// Schedule an automatic retry for discover after certain amount of time.
    private func scheduleBrowserRetry() {
        guard let queue = queue, isStarted else { return }

        // Automatically retry until the user cancels
        queue.asyncAfter(deadline: .now() + .seconds(configuration.autoRetryConnectInterval)) { [weak self] in
            self?.startBrowser()
        }
    }
    
    /// Connect automatically to a preferred server, if any.
    private func connectAutomaticallyIfNeeded() {
        if isStarted && connectedServer != nil {
            return
        }

        // Will connect automatically to the server endpoint.
        let server = suitableServer()
        if let server = server {
            connect(to: server)
        }
    }
    
    private func suitableServer() -> NWBrowser.Result? {
        guard servers.isEmpty == false else {
            return nil
        }
        
        guard let serverName = configuration.autoConnectServerName else {
            if configuration.autoConnectAvailableServer {
                return servers.first
            } else {
                return nil
            }
        }
        
        let found = servers.first {
            $0.name == serverName
        }
        return found
    }
    
    /// Connects to the given server and saves the selection persistently. Cancels
    /// the existing connection.
    public func connect(to server: NWBrowser.Result) {
        guard let name = server.name else {
            delegate?.remoteTransport(self, errorOccurred: .init(message: "Server name is missing"))
            return
        }

        // Save selection for the future
        selectedServer = name

        queue?.async { [weak self] in
            guard let self = self else { return }
            
            switch self.connectionState {
            case .idle:
                self.openConnection(to: server)
            case .connecting, .connected:
                guard self.connectedServer != server else { return }
                self.cancelConnection()
                self.openConnection(to: server)
            }
        }
    }
    
    /// Connected to the remote server.
    ///
    /// - Parameter server: server to connect.
    private func openConnection(to server: NWBrowser.Result) {
        guard let queue = queue else {
            return
        }

        connectedServer = server
        connectionState = .connecting

        delegate?.remoteTransport(self, willStartConnectionTo: server.endpoint)

        let server = servers.first(where: { $0.name == server.name }) ?? server

        let connection = Connection(endpoint: server.endpoint)
        connection.delegate = self
        connection.start(on: queue)
        self.connection = connection
    }
    
    /// Close active connection.
    private func cancelConnection() {
        connectionState = .idle // The order is important
        connectedServer = nil

        connection?.cancel()
        connection = nil

        connectionRetryItem?.cancel()
        connectionRetryItem = nil

        cancelPingPong()
    }
    
    /// Cancel connection
    private func cancel() {
        guard isStarted else { return }
        isStarted = false

        cancelBrowser()
        cancelConnection()
    }
    
    /// Cancel ping pong handshacke while pausing.
    private func cancelPingPong() {
        timeoutDisconnectItem?.cancel()
        timeoutDisconnectItem = nil

        pingItem?.cancel()
        pingItem = nil
    }
    
    // MARK: - Private Function (Server Connection)
    
    /// Perform sever handshake.
    private func performServerHandshake() {
        guard let connection = connection else {
            return
        }
        
        delegate?.remoteTransport(self, willHandshakeWithConnection: connection)

        // Say "hello" to the server and share information about the client
        connection.sendPacket(PacketHello())

        // Set timeout and retry in case there was no response from the server
        queue?.asyncAfter(deadline: .now() + .seconds(10)) { [weak self] in
            guard let self = self else { return } // Failed to connect in 10 sec
            
            guard self.connectionState == .connecting else { return }
            
            self.delegate?.remoteTransport(self,
                                           connection: connection,
                                           error: .init(message: "The handshake with the server timed out. Will retry in few moments."))
            self.scheduleConnectionRetry()
        }
    }
    
    
    /// Will retry connection to the server after certain interval.
    private func scheduleConnectionRetry() {
        guard connectionState != .idle, connectionRetryItem == nil else { return }

        cancelPingPong()

        connectionState = .connecting

        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.connectionRetryItem = nil
            guard self.connectionState == .connecting,
                  let server = self.connectedServer else { return }
            self.openConnection(to: server)
        }
        queue?.asyncAfter(deadline: .now() + .seconds(2), execute: item)
        connectionRetryItem = item
    }
    
    private func schedulePeriodicPingToCurrentConnection() {
        connection?.sendPacketCode(.ping)

        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            guard self.connectionState == .connected else { return }
            self.schedulePeriodicPingToCurrentConnection()
        }
        
        queue?.asyncAfter(deadline: .now() + .seconds(2), execute: item)
        pingItem = item
    }
    
    private func scheduleAutomaticDisconnect() {
        timeoutDisconnectItem?.cancel()

        guard connectionState == .connected else { return }

        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            guard self.connectionState == .connected else { return }
            
            let error = GliderError(message: "Haven't received pings from a server in a while, disconnecting")
            self.delegate?.remoteTransport(self, connection: self.connection!, error: error)

            self.scheduleConnectionRetry()
        }
        
        queue?.asyncAfter(deadline: .now() + .seconds(4), execute: item)
        timeoutDisconnectItem = item
    }
    
    // MARK: - Incoming Messages
    
    private func didReceivePacket(_ packet: RawPacket, fromConnection connection: Connection) {
        let code = PacketCode(rawValue: packet.code)
        switch code {
        case .serverHello:
            guard connectionState != .connected else { return }
            connectionState = .connected
            schedulePeriodicPingToCurrentConnection()
            
        case .pause:
            isLoggingPaused = true
            
        case .resume:
            isLoggingPaused = false
            buffer?.forEach {
                connection.sendEvent($0)
            }
            
        case .ping:
            scheduleAutomaticDisconnect()
            
        default:
            // Invalid packet code received.
            break
        }
    }
    
}

// MARK: - RemoteTransport Connection Manager

extension RemoteTransport: RemoteTransportConnectionDelegate {
    
    public func connection(_ connection: Connection, didChangeState newState: NWConnection.State) {
        guard connectionState != .idle else { return }

        delegate?.remoteTransport(self, connection: connection, didChangeState: newState)

        switch newState {
        case .ready:
            performServerHandshake()
        case .failed, .cancelled:
            scheduleConnectionRetry()
        default:
            break
        }
    }
    
    /// A new event from the other connection side has been received.
    ///
    /// - Parameters:
    ///   - connection: connection source.
    ///   - event: event.
    public func connection(_ connection: Connection, didReceiveEvent event: RemoteTransport.RemoteEvent) {
        guard connectionState != .idle else { return }

        switch event {
        case .packet(let packet):
            didReceivePacket(packet, fromConnection: connection)

        case .error:
            scheduleConnectionRetry()
            
        case .completed:
            break
        }
    }
    
    public func connection(_ connection: Connection, failedToSendPacket packet: RemoteTransportPacket, error: Error) {
        delegate?.remoteTrasnport(self, connection: connection, failedToSendPacket: packet, error: error)
    }
    
    public func connection(_ connection: Connection, failedToDecodingPacketData data: Data, error: Error) {
        delegate?.remoteTrasnport(self, connection: connection, failedToDecodingPacketData: data, error: error)
    }
    
}
