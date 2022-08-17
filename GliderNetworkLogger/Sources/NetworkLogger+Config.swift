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

extension NetworkLogger {
    
    /// Represent the configuration object for network logger request.
    public struct Config {
        
        // MARK: - Public Properties
        
        /// Identify where the data are saved.
        public var storage: Storage
        
        /// Hosts that will be ignored from being recorded.
        public var ignoredHosts = [String]()
        
        // MARK: - Initialization
        
        /// Initialize a new remote configuration object via builder function.
        ///
        /// - Parameter builder: builder callback.
        public init(storage: Storage, _ builder: ((inout Config) -> Void)?) {
            self.storage = storage
            builder?(&self)
        }
        
    }
    
}

extension NetworkLogger.Config {
    
    public enum Storage {
        case inMemory(limit: Int)
        case database(fileURL: URL)
        case folder(url: URL)
    }
    
}
