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
import Glider

/// The `NetworkLogger` class is used to perform networking monitoring of your app.
/// It will intercepts any call coming from a third party library like RealHTTP or Alamofire
/// and URLSession too. It allows to specify a `Log` instance where the logs are redirected to.
public class NetworkLogger {
  
    // MARK: - Public Properties
    
    /// Singleton instance.
    public static let shared = NetworkLogger()
    
    /// Active configuration.
    public private(set) var config: Config?
    
    /// Return `true` if recording globally or at least one configuration is on.
    public private(set) var isActive: Bool = false
    
    /// Hosts that will be ignored from being recorded.
    public var ignoredHosts: [String] {
        get { LoggerURLProtocol.ignoredHosts }
        set { LoggerURLProtocol.ignoredHosts = newValue }
    }
    
    // MARK: - Initialization
    
    private init() { }
    
    // MARK: - Public Functions
    
    /// Modify the configuration.
    ///
    /// NOTE:
    /// You should never call it while recording is in progress.
    /// In this case no changes are applied.
    ///
    /// - Parameter configuration: new configuration
    @discardableResult
    public func setConfiguration(_ config: Config) -> Bool {
        guard isActive == false else {
            return false
        }
        
        self.config = config
        self.ignoredHosts = config.ignoredHosts
        return true
    }
    
    public func captureGlobally(_ enabled: Bool) {
        if enabled {
            URLProtocol.registerClass(LoggerURLProtocol.self)
        } else {
            URLProtocol.unregisterClass(LoggerURLProtocol.self)
        }
    }
    
    @discardableResult
    public func capture(_ enabled: Bool, forSessionConfiguration configuration: URLSessionConfiguration) -> Bool {
        guard isActive == false else {
            return false
        }
        
        var urlProtocolClasses = configuration.protocolClasses
        guard urlProtocolClasses != nil else {
            return false
        }
        
        let index = urlProtocolClasses?.firstIndex(where: { (obj) -> Bool in
            if obj == LoggerURLProtocol.self {
                return true
            }
            return false
        })
        
        if enabled && index == nil {
            urlProtocolClasses!.insert(LoggerURLProtocol.self, at: 0)
        } else if !enabled && index != nil{
            urlProtocolClasses!.remove(at: index!)
        }
        configuration.protocolClasses = urlProtocolClasses
        return true
    }
    
}
