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
import Glider

extension NetArchiveTransport {
    
    /// Configuration for `NetArchiveTransport`.
    public struct Configuration {
        
        // MARK: - Public Properties
        
        /// Is the transport enabled. By default is set to `true`.
        public var isEnabled = true
        
        /// The `DispatchQueue` to use for the recorder.
        public var queue: DispatchQueue
        
        /// Local database file URL.
        public var databaseLocation: SQLiteDb.Location
        
        /// Options for database creation.
        /// By default is the standard initialization of `SQLiteDb.Options`.
        public var databaseOptions: SQLiteDb.Options = .init()
        
        /// Throttled transport used to perform buffering on database.
        ///
        /// By default is initialized with the default configuration
        /// of the `ThrottledTransport`.
        public var throttledTransport = ThrottledTransport.Configuration()
        
        /// The maximum age of a log before it it will be removed automatically
        /// to preserve the space. Set as you needs.
        ///
        /// By default is 1h.
        public var lifetimeInterval: TimeInterval?
        
        /// Flushing old logs can't happens every time we wrote something
        /// on db. So this interval is the minimum time interval to pass
        /// before calling flush another time.
        /// Typically is set as 3x the `logsLifeTimeInterval`.
        public var purgeMinInterval: TimeInterval?
        
        // MARK: - Initialization
        
        /// Initialize a new remote configuration object via builder function.
        ///
        /// - Parameter builder: builder callback.
        public init(location: SQLiteDb.Location, _ builder: ((inout Configuration) -> Void)? = nil) {
            self.databaseLocation = location
            self.queue = DispatchQueue(label: String(describing: type(of: self)), attributes: [])
            self.throttledTransport.autoFlushInterval = 3
            self.purgeMinInterval = (lifetimeInterval != nil ? lifetimeInterval! * 3.0 : nil)
            builder?(&self)
        }
        
    }
    
}
