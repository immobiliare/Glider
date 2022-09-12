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

public extension NetSparseFilesTransport {
    
    /// Configuration for `NetSparseFilesTransport`.
    struct Configuration {
        
        // MARK: - Public Properties
        
        /// Is the transport enabled. By default is set to `true`.
        public var isEnabled = true
        
        /// The `DispatchQueue` to use for the recorder.
        public var queue: DispatchQueue
        
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
            self.queue = DispatchQueue(label: String(describing: type(of: self)), attributes: [])
            builder?(&self)
        }
        
    }
    
}
