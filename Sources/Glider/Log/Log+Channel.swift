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
    
    public class Channel {
        
        // MARK: - Private Properties
        
        /// Weak reference to the parent log instance.
        internal weak var log: Log?
        
        /// Level of severity represented by the log instance.
        internal let level: Level
        
        // MARK: - Initialization
        
        /// Initialize a new log instance.
        /// - Parameters:
        ///   - log: log instance.
        ///   - level: level represented by the channel.
        internal init(for log: Log, level: Level) {
            self.log = log
            self.level = level
        }
        
        // MARK: - Public Functions 
        
        public func write(_ eventBuilder: @escaping () -> Event,
                          function: String = #function, filePath: String = #file, fileLine: Int = #line) {
            
            guard let log = log, log.isEnabled else { return }
            
            let event = eventBuilder()
            event.scope.
            
            log.transporter.write(eventBuilder())
        }
        
    }
    
}
