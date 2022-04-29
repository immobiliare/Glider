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

public class Log: Equatable {
    
    // MARK: - Configuration
    
    /// Unique identifier of the log instance.
    public let uuid = UUID()
    
    /// Current level of severity of the log instance.
    /// Messages below set level are ignored automatically.
    public private(set) var level: Level = .debug
    
    /// Is logging enabled. When logging is disabled any message
    /// sent to any channels is discarded automatically and not evaluated.
    public var isEnabled: Bool = true
    
    // MARK: - Channels
    
    /// Subscript to access to a specific level channel.
    public subscript(level: Level) -> Channel? {
        channels[level.rawValue]
    }
    
    /// `debug` channel receive messages meant to be useful
    /// only during development.
    public var debug: Channel? { channels[Level.debug.rawValue] }
    
    /// `info` channel receive ionformational messages that
    /// are not essential for troubleshooting errors.
    public var info: Channel? { channels[Level.info.rawValue] }
    
    /// `notice` channel receive messages which cannot be threat as an
    /// error but that may require special handling.
    public var notice: Channel? { channels[Level.notice.rawValue] }
    
    /// `warning` channel receive messages which reports abnormal conditions
    /// that do not prevent the program from completing a specific task.
    public var warning: Channel? { channels[Level.warning.rawValue] }
    
    /// `error` channel receive messages which must be threated as errors.
    public var error: Channel? { channels[Level.error.rawValue] }
    
    /// `critical` channel receive messages could have a significant performance cost.
    public var critical: Channel? { channels[Level.critical.rawValue] }
    
    /// `alert` channel receive messages which require to take an immediate action.
    public var alert: Channel? { channels[Level.alert.rawValue] }
    
    /// `emergency` channel receive messages when application is unusable.
    public var emergency: Channel? { channels[Level.emergency.rawValue] }

    /// The low-level interface for accepting log messages.
    public let transporter: Transporter
    
    // MARK: - Private Properties
    
    /// This is the queue used to change the value of the log level.
    private let channelsQueue: DispatchQueue
    
    /// Channels are the primary sources which receive messages from log.
    /// All messages are received in order; only some channels are initialized
    /// based upon the current log severity.
    /// Non active channel's related levels are `nil` so the lowest impact is made
    /// on target application.
    internal var channels: [Channel?] = .init(repeating: nil, count: Level.allCases.count)
    
    // MARK: - Initialization
    
    public init(_ builder: ((inout Configuration) -> Void)) {
        self.channelsQueue = DispatchQueue(label: "com.log.channels.\(uuid.uuidString)")
        
        var config = Configuration()
        builder(&config)
        
        self.transporter = Transporter(configuration: config)
        self.isEnabled = config.isEnabled
        setLevel(config.level)
    }
    
    // MARK: - Public Functions
    
    /// Change the severity level of the log instance. Messages sent using a lower level
    /// message are ignored automatically.
    ///
    /// - Parameter level: level to set.
    public func setLevel(_ level: Level) {        
        channelsQueue.sync {
            self.level = level
            
            Level.allCases.forEach { cLevel in
                channels[cLevel.rawValue] = (cLevel > level ? nil :  Channel(for: self, level: cLevel))
            }
        }
    }
    
    public static func == (lhs: Log, rhs: Log) -> Bool {
        lhs.uuid == rhs.uuid
    }
        
}
