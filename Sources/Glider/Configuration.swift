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

extension Log {
    
    public struct Configuration {
        
        /// Subsystem of the log.
        public var subsystem: LogIdentifiable = ""
        
        /// Category identiifer of the log.
        public var category: LogIdentifiable = ""
        
        // Minimum severity level for this logger.
        // Messages sent to a logger with a level lower than this will be automatically
        // ignored by the system. By default this value is set to `info`.
        public var level: Level = .info
        
        /// Defines if a log is active and can receive messages.
        /// By default is `true`.
        public var enabled: Bool = true
    }
    
}
