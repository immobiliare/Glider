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

// MARK: - HTTPServer

public class HTTPServer {
    
    // MARK: - Public Properties
    
    /// State of the server.
    public private(set) var state = HTTPServerState.idle {
        didSet { delegate?.serverDidChangeState(self, state: state) }
    }
    
    /// Delegate of the server.
    public weak var delegate: HTTPServerDelegate?
    
    // MARK: - Private Properties
    
    private var listeningHandle: FileHandle?
    private var socket: CFSocket?
    private var incomingRequests = [FileHandle: CFHTTPMessage]()
    
    // MARK: - Public Function
    
    /// Start an HTTP server at given port.
    ///
    /// - Parameter port: port of listing.
    public func start(port: UInt16) throws {
        state = .starting
        guard let socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, 0, nil, nil) else {
            throw HTTPServerError.socketCreationFailed
        }
        
        self.socket = socket
        
        var reuse = 1
        let fileDescriptor = CFSocketGetNative(socket)
        if setsockopt(fileDescriptor, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int>.size)) != 0 {
            throw HTTPServerError.socketSetOptionFailed
        }
        
        var noSigPipe = 1
        if setsockopt(fileDescriptor, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, socklen_t(MemoryLayout<Int>.size)) != 0 {
            throw HTTPServerError.socketSetOptionFailed
        }
        
        var address = sockaddr_in(sin_len: __uint8_t(MemoryLayout<sockaddr_in>.size),
                                  sin_family: sa_family_t(AF_INET),
                                  sin_port: port.bigEndian,
                                  sin_addr: in_addr(s_addr: INADDR_ANY.bigEndian),
                                  sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        
        let addressData = Data(bytes: &address, count: MemoryLayout<sockaddr_in>.size)
        switch CFSocketSetAddress(socket, addressData as CFData) {
        case .success:
            break
        case .error:
            throw HTTPServerError.socketSetAddressFailed
        case .timeout:
            throw HTTPServerError.socketSetAddressTimeout
        @unknown default:
            throw HTTPServerError.unknown
        }
        
        if listen(fileDescriptor, 5) != 0 {
            throw HTTPServerError.socketListenFailed
        }
        
        let listeningHandle = FileHandle(fileDescriptor: fileDescriptor, closeOnDealloc: true)
        self.listeningHandle = listeningHandle
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(receiveIncomingConnectionNotification(_:)),
                                               name: .NSFileHandleConnectionAccepted,
                                               object: listeningHandle)
        listeningHandle.acceptConnectionInBackgroundAndNotify()
        state = .running
    }
    
    /// Stop server.
    public func stop() {
        state = .stopping
        NotificationCenter.default.removeObserver(self, name: .NSFileHandleConnectionAccepted, object: nil)
        listeningHandle?.closeFile()
        listeningHandle = nil
        for incomingFileHandle in incomingRequests.keys {
            stopReceiving(for: incomingFileHandle, close: true)
        }
        if let socket = socket {
            CFSocketInvalidate(socket)
        }
        socket = nil
        state = .idle
    }
    
    // MARK: - Private Functions
    
    private func stopReceiving(for incomingFileHandle: FileHandle, close closeFileHandle: Bool) {
        if closeFileHandle {
            incomingFileHandle.closeFile()
        }
        NotificationCenter.default.removeObserver(self, name: .NSFileHandleDataAvailable, object: incomingFileHandle)
        incomingRequests.removeValue(forKey: incomingFileHandle)
    }
    
    @objc
    private func receiveIncomingConnectionNotification(_ notification: Notification) {
        if let incomingFileHandle = notification.userInfo?[NSFileHandleNotificationFileHandleItem] as? FileHandle {
            let message = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, true)
            incomingRequests[incomingFileHandle] = message.autorelease().takeUnretainedValue()
            NotificationCenter.default.addObserver(self, selector: #selector(receiveIncomingDataNotification(_:)), name: .NSFileHandleDataAvailable, object: incomingFileHandle)
            incomingFileHandle.waitForDataInBackgroundAndNotify()
        }
        listeningHandle?.acceptConnectionInBackgroundAndNotify()
    }
    
    @objc
    private func receiveIncomingDataNotification(_ notification: Notification) {
        guard let incomingFileHandle = notification.object as? FileHandle else { return }
        let data = incomingFileHandle.availableData
        guard !data.isEmpty else {
            return stopReceiving(for: incomingFileHandle, close: false)
        }
        
        guard let incomingRequest = incomingRequests[incomingFileHandle] else {
            return stopReceiving(for: incomingFileHandle, close: true)
        }
        
        data.withUnsafeBytes { pointer in
            guard let bytes = pointer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                stopReceiving(for: incomingFileHandle, close: true)
                return
            }
            CFHTTPMessageAppendBytes(incomingRequest, bytes, data.count)
        }
        
        guard CFHTTPMessageIsHeaderComplete(incomingRequest) else {
            return incomingFileHandle.waitForDataInBackgroundAndNotify()
        }
        
        defer {
            stopReceiving(for: incomingFileHandle, close: false)
        }
        
        delegate?.server(self, didReceiveRequest: incomingRequest, fileHandle: incomingFileHandle) { [weak self] in
            self?.stopReceiving(for: incomingFileHandle, close: true)
        }
    }
}

extension HTTPServer {
    
    // MARK: - HTTPServerState
    
    /// State of the server.
    public enum HTTPServerState {
        case idle
        case starting
        case running
        case stopping
    }
    
    // MARK: - HTTPServerError
    
    /// Error states.
    public enum HTTPServerError: Error, CustomNSError {
        case socketCreationFailed
        case socketSetOptionFailed
        case socketSetAddressFailed
        case socketSetAddressTimeout
        case socketListenFailed
        case unknown
        
        public static let domain: NSErrorDomain = "HTTPServerError"
    }
    
}

// MARK: - HTTPServerDelegate

public protocol HTTPServerDelegate: AnyObject {
    
    /// Called when server did change state.
    ///
    /// - Parameter server: server.
    func serverDidChangeState(_ server: HTTPServer, state: HTTPServer.HTTPServerState)
    
    /// Called when server receive a new request.
    ///
    /// - Parameters:
    ///   - server: server instance.
    ///   - request: request receiver.
    ///   - fileHandle: handler IO to pass response.
    ///   - completion: completion to call at the end.
    func server(_ server: HTTPServer, didReceiveRequest request: CFHTTPMessage, fileHandle: FileHandle, completion: @escaping () -> Void)

}
