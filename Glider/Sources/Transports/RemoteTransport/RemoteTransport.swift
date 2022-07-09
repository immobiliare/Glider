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
/// It's used when you want to debug sessions to the GliderViewer client or similar.
/// Usually you should use a single instance of this transport for all of yours log.
/// In this case use the `RemoteTransport.shared` shortcut instead of creating a new one.
public class RemoteTransport: Transport {
    
    // MARK: - Public Properties
    
    /// Configuration object.
    public let configuration: Configuration
 
    /// Delegate object to receive messages.
    public weak var delegate: RemoteTransportDelegate?
    
    /// Used to temporary disable logging to remote destination without
    /// disconnecting from the endpoint.
    /// Logs are stored into the internal buffer (not truncated) and send once possible.
    public var isLoggingPaused: Bool = false
    
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

    private var buffer: [Event]? = []

    // MARK: - Initialization
    
    /// Initialize with configuration.
    ///
    /// - Parameter configuration: configuration.
    public init(configuration: Configuration, delegate: RemoteTransportDelegate? = nil) throws {
        self.configuration = configuration
        self.isEnabled = true
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
    
    /// Initialize a new remote transport.
    ///
    /// - Parameters:
    ///   - delegate: delegate for events.
    ///   - builder: builder to configure extra options.
    public convenience init(host: String, port: Int,
                delegate: RemoteTransportDelegate? = nil,
                _ builder: ((inout Configuration) -> Void)? = nil) throws {
        try self.init(configuration: Configuration(builder), delegate: delegate)
    }
    
    // MARK: - Public Functions
    
    public func record(event: Event) -> Bool {
        if isLoggingPaused {
            buffer?.append(event)
            return true
        } else {
            let packet = PacketEvent(event: event)
            return connection?.send(packet: packet) ?? false
        }
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
        guard isStarted else { return }

        guard !selectedServer.isEmpty,
                connectedServer == nil,
              let server = self.servers.first(where: { $0.name == selectedServer }) else {
            return
        }

        // Will connect automatically to the server endpoint.
        connect(to: server)
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
    
    private func cancelPingPong() {
        timeoutDisconnectItem?.cancel()
        timeoutDisconnectItem = nil

        pingItem?.cancel()
        pingItem = nil
    }
    
    // MARK: - Private Function (Server Connection)
    
    private func handshakeWithServer() {
        guard let connection = connection else {
            return
        }
        
        delegate?.remoteTransport(self, willHandshakeWithConnection: connection)

        // Say "hello" to the server and share information about the client
        connection.send(packet: PacketClientHello())

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
    
}

extension RemoteTransport: RemoteTransportConnectionDelegate {
    
    public func connection(_ connection: Connection, didChangeState newState: NWConnection.State) {
        guard connectionState != .idle else { return }

        delegate?.remoteTransport(self, connection: connection, didChangeState: newState)

        switch newState {
        case .ready:
            handshakeWithServer()
        case .failed:
            scheduleConnectionRetry()
        default:
            break
        }
    }
    
    public func connection(_ connection: Connection, didReceiveEvent event: Connection.Event) {
        guard connectionState != .idle else { return }

        switch event {
        case .packet(let packet):
            do {
                try didReceiveMessage(packet: packet)
            } catch {
                delegate.
                log(label: "RemoteLogger", "Invalid message from the server: \(error)")
            }
        case .error:
            scheduleConnectionRetry()
        case .completed:
            break
        }
        
    }
    
    public func connection(_ connection: Connection, failedToProcessingPacket data: Data, error: Error) {
        
    }
    
    public func connection(_ connection: Connection, failedToEncodingObject: Any, error: Error) {
        
    }
    
    public func connection(_ connection: Connection, failedToSendData data: Data, error: NWError) {
        
    }
    
    
}
