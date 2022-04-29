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

    /// Write a new event to the current channel.
    /// If parent log is disabled or channel's level is below log's level message is ignored and
    /// returned data is `nil`. Otherwise, when event is correctly dispatched to the underlying
    /// transport services it will return the `Event` instance sent.
    ///
    /// - Parameters:
    ///   - eventBuilder: builder function for event
    ///   - function: function name of the caller (filled automastically)
    ///   - filePath: file path of the caller (filled automatically)
    ///   - fileLine: file line of the caller (filled automatically)
    /// - Returns: Event
    @discardableResult
    public func write(_ eventBuilder: @escaping () -> Event,
                      function: String = #function, filePath: String = #file, fileLine: Int = #line) -> Event? {
        
        guard let log = log, log.isEnabled else {
            return nil
        }
        
        // Generate the event and decorate it with the current scope and runtime attributes
        var event = eventBuilder()
        event.scope.runtimeContext = .init(function: function, filePath: filePath, fileLine: fileLine)
        
        log.transporter.write(event)
        return event
    }
    
}
