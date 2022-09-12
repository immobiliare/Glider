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

/// `BonjourPublisher` publish the availability a service over the local network.
/// This is typically used by WebSocket transports in order to publish the service for
/// a local application.
public class BonjourPublisher {
    
    // MARK: - Public Properties
    
    /// Delegate
    public var delegate: BonjourPublisherDelegate? {
        get { objectDelegate?.delegate }
        set { objectDelegate?.delegate = newValue }
    }
    
    /// Identifier of the service.
    public var identifier: String {
        netService.type
    }
    
    public let configuration: Configuration
    
    // MARK: - Private Properties.
    
    /// NetService used to publish services over bonjour.
    private var netService: NetService
    
    /// Delegate.
    private var objectDelegate: BonjourPublisherObjectDelegate?
    
    /// Callback.
    var successCallback: ((Bool) -> Void)?
    
    public fileprivate(set) var started = false {
        didSet {
            successCallback?(started)
            successCallback = nil
        }
    }
    
    /// Text record.
    public var txtRecord: [String: String]? {
        get {
            return netService.txtRecordDictionary
        }
        set {
            netService.setTXTRecord(dictionary: newValue)
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize a new bonjour advertising service.
    ///
    /// - Parameter cfg: configuration
    public init(configuration cfg: Configuration) {
        self.configuration = cfg
        
        netService = NetService(domain: cfg.domain, type: cfg.type.description, name: cfg.name, port: cfg.port)
        objectDelegate = BonjourPublisherObjectDelegate()
        objectDelegate?.server = self
        netService.delegate = objectDelegate
    }

    deinit {
        stop()
        netService.delegate = nil
        objectDelegate = nil
    }

    // MARK: - Public Functions
    
    /// Start server.
    ///
    /// - Parameters:
    ///   - options: options.
    ///   - success: success handler.
    public func start(options: NetService.Options = [.listenForConnections],
                      success: ((Bool) -> Void)? = nil) {
        
        let runLoop: RunLoop = .main
        if started {
            success?(true)
            return
        }
        
        successCallback = success
        netService.schedule(in: runLoop, forMode: .default)
        netService.publish(options: options)
     //   runLoop.run()
    }
    
    /// Stop service.
    public func stop() {
        netService.stop()
    }
    
}

// MARK: - BonjourPublisherDelegate

/// This class is used only to incapsulate the objective-c requirements of the NetServiceDelegate.
private class BonjourPublisherObjectDelegate: NSObject, NetServiceDelegate {
    weak var server: BonjourPublisher?
    
    weak var delegate: BonjourPublisherDelegate?
    
    init(delegate: BonjourPublisherDelegate? = nil) {
        self.delegate = delegate
    }

    func netServiceDidPublish(_ sender: NetService) {
        server?.started = true
        delegate?.bonjourPublisherDidStart(server!)
    }

    func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        server?.started = false
        let error = GliderError(message: errorDict.description)
        delegate?.bonjourPublisher(server!, didStopWithError: error)
    }

    func netServiceDidStop(_ sender: NetService) {
        server?.started = false
        delegate?.bonjourPublisher(server!, didStopWithError: nil)
    }

}

// MARK: - BonjourPublisherDelegate

public protocol BonjourPublisherDelegate: AnyObject {
    
    /// Called when bonjur service is active.
    ///
    /// - Parameter publisher: publisher instance.
    func bonjourPublisherDidStart(_ publisher: BonjourPublisher)
    
    /// Called when bonjour service did stop.
    ///
    /// - Parameters:
    ///   - publisher: publisher.
    ///   - error: if an error occurred it contains info.
    func bonjourPublisher(_ publisher: BonjourPublisher, didStopWithError error: Error?)
    
}
