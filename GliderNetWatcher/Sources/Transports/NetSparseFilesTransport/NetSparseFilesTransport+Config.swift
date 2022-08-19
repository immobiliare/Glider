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

public extension NetSparseFilesTransport {
    
    /// Configuration for `NetSparseFilesTransport`.
    struct Configuration {
        
        // MARK: - Public Properties
        
        /// Is the transport enabled. By default is set to `true`.
        public var isEnabled = true
        
        /// The GCD dispatch queue to use.
        /// If not specified a queue is created for you.
        public var queue: DispatchQueue?
        
        /// URL of the folder where to store each call.
        public var directoryURL: URL
        
        /// Reset at each initialization.
        /// By default is set to `false`.
        public var resetAtStartup: Bool = false
        
        // MARK: - Initialization
                
        /// Initialize a new remote configuration object via builder function.
        ///
        /// - Parameter builder: builder callback.
        public init(directoryURL: URL, _ builder: ((inout Configuration) -> Void)? = nil) {
            self.directoryURL = directoryURL
            self.queue = DispatchQueue(label: "com.glider.netwatcher.sparsefiles")
            builder?(&self)
        }
        
    }
    
}
