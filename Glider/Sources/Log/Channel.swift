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
    ///
    /// - Parameters:
    ///   - eventBuilder: builder function for event
    ///   - function: function name of the caller (filled automastically)
    ///   - filePath: file path of the caller (filled automatically)
    ///   - fileLine: file line of the caller (filled automatically)
    /// - Returns: Event
    @discardableResult
    public func write(_ eventBuilder: @escaping (inout Event) -> Void,
                      function: String = #function, filePath: String = #file, fileLine: Int = #line) -> Event? {
        
        guard let log = log, log.isEnabled else {
            return nil
        }
        
        // Generate the event and decorate it with the current scope and runtime attributes
        var event = Event()
        eventBuilder(&event)
        return write(event: &event, function: function, filePath: filePath, fileLine: fileLine)
    }
    
    /// Write a new event to the current channel.
    /// If parent log is disabled or channel's level is below log's level message is ignored and
    /// returned data is `nil`. Otherwise, when event is correctly dispatched to the underlying
    /// transport services it will return the `Event` instance sent.
    ///
    /// - Parameters:
    ///   - event: event to write
    ///   - function: function name of the caller (filled automastically)
    ///   - filePath: file path of the caller (filled automatically)
    ///   - fileLine: file line of the caller (filled automatically)
    /// - Returns: Event
    @discardableResult
    public func write(event: inout Event,
                      function: String = #function, filePath: String = #file, fileLine: Int = #line) -> Event? {
        guard let log = log, log.isEnabled else {
            return nil
        }
        
        // Generate the event and decorate it with the current scope and runtime attributes
        event.level = self.level
        event.subsystem = log.subsystem.id
        event.category = log.category.id
        event.scope.attach(function: function, filePath: filePath, fileLine: fileLine)
        
        log.transporter.write(&event)
        return event
    }
    
    /// Write a new message (both as literal or computed function which return a string)  into the current channel.
    /// String's value is evaluated only if channel is active and the level should be included.
    /// This is pretty useful when your message is not a literal string but must be evaluated.
    ///
    /// NOTE: The underlying `Event` object is created automatically for you.
    ///
    /// See the notes on `write()` function for `Event` instance for more infos.
    ///
    /// - Parameters:
    ///   - messageBuilder: function which generate the message string to send.
    ///                     this function which will be executed only if the message is actually sent
    ///                     in order to avoid unnecessary overheads when the generation may result expensive.
    ///   - object: object you can send for automatic serialization.
    ///   - extra: extra data to associate.
    ///   - tags: extra indexable tags to associate.
    ///   - function: function name of the caller (filled automastically)
    ///   - filePath: file path of the caller (filled automatically)
    ///   - fileLine: file line of the caller (filled automatically)
    /// - Returns: Event
    @discardableResult
    public func write(msg message: @autoclosure @escaping () -> Event.Message,
                      object: SerializableObject? = nil,
                      extra: Metadata? = nil,
                      tags: Tags? = nil,
                      function: String = #function, filePath: String = #file, fileLine: Int = #line) -> Event? {
        
        guard let log = log, log.isEnabled else {
            return nil
        }
        
        return write({
            $0.message = message()
            $0.object = object
            $0.extra = (self.log?.extra != nil ? self.log!.extra.merge(with: extra) : extra)
            $0.tags = (self.log?.tags != nil ? Dictionary.merge(baseDictionary: self.log!.tags, additionalData: tags) : tags)
        }, function: function, filePath: filePath, fileLine: fileLine)
    }
    
}

