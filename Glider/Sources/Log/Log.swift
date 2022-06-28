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
    
    /// Full label of the log.
    ///
    /// NOTE:
    /// It's composed by the subsystem and category
    /// separated by a comma trimming whitespaces and newlines.
    public lazy var label: String = {
        [subsystem.id, category.id]
            .map({
                $0.wipeCharacters(characters: "\n\r ")
            })
            .filter({
                $0.isEmpty == false
            })
            .joined(separator: ".")
    }()
    
    /// Subsystem helps you to track and identify the logger. Typically this is
    /// the bundle identifier of the package which produce the log messages.
    ///
    /// For example you may use "com.myapp.storage" for a logger
    /// in your separate storage framework package.
    public let subsystem: LoggerIdentifiable
    
    /// You can use category to further distinguish a logger inside the same
    /// subsystem.
    /// For example you may use "messageStorage" or "usersStorage" to
    /// separate two logger in the same "com.myapp.storage"'s subsystem.
    public let category: LoggerIdentifiable
    
    /// Current level of severity of the log instance.
    /// Messages below set level are ignored automatically.
    public private(set) var level: Level = .debug
    
    /// Is logging enabled. When logging is disabled any message
    /// sent to any channels is discarded automatically and not evaluated.
    public var isEnabled: Bool = true
    
    /// Tags are key/value string pairs.
    /// Values are merged with the current scope and events specific tags.
    public var tags = Tags()
    
    /// Arbitrary additional information that will be sent with the event.
    /// Values are merged with the current scope and events specific tags.
    public var extra = Metadata()
    
    // MARK: - Channels
    
    /// Subscript to access to a specific level channel.
    public subscript(level: Level) -> Channel? {
        channels[level.rawValue]
    }
    
    /// `trace` channel receive messages for tracing purposes.
    public var trace: Channel? { channels[Level.trace.rawValue] }
    
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
    
    /// Define a list
    public var filters: [TransportFilter] {
        set { transporter.filters = newValue }
        get { transporter.filters }
    }
    
    // MARK: - Private Properties
    
    /// The low-level interface for accepting log messages.
    internal let transporter: TransportManager
    
    /// This is the queue used to change the value of the log level.
    private let channelsQueue: DispatchQueue
    
    /// Channels are the primary sources which receive messages from log.
    /// All messages are received in order; only some channels are initialized
    /// based upon the current log severity.
    /// Non active channel's related levels are `nil` so the lowest impact is made
    /// on target application.
    internal var channels: [Channel?] = .init(repeating: nil, count: Level.allCases.count)
    
    // MARK: - Initialization
    
    /// Initialize with configuration.
    ///
    /// - Parameter config: configuration.
    public init(configuration config: Configuration) {
        self.channelsQueue = DispatchQueue(label: "com.log.channels.\(uuid.uuidString)")

        self.transporter = TransportManager(configuration: config)
        self.isEnabled = config.isEnabled
        self.category = config.category
        self.subsystem = config.subsystem
        setLevel(config.level)
    }
    
    /// Initialize with configuration builder callback.
    ///
    /// - Parameter builder: builder.
    public convenience init(_ builder: ((inout Configuration) -> Void)) {
        let config = Configuration(builder)
        self.init(configuration: config)
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
