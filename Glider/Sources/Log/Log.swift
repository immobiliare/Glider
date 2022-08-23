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

/// `Log` class represents an instance of a logger, which is the entry point for all your application's messages.
/// You can create one or multiple logger instances depending on the complexity of your application infrastructure or your needs.
///
/// Log messages in Glider are events; when you create a new log entry for a `Log` instance,
/// you're making a payload of type `Event` representing a snapshot of the application into a particular moment.
/// Each `Event` has a message text (which describes a context), a severity level (to indicate the typology of the message,
/// from notice to a warning or error), and some additional context properties like metadata, stack trace, or attached objects.
///
/// To initialize a logger, you can pass a `Configuration` object or, more quickly, by using a configuration callback.
/// A logger is uniquely identified by a pair of properties: `subsystem` and `category`; `subsystem` helps you to track
/// and identify the logger. Typically this is the bundle identifier of the package which produces the log messages.
/// You can use `category` further to distinguish a logger inside the same `subsystem`.
///
/// Logger also exposes two important properties:
/// Severity `level`: indicates the minimum severity accepted by the log. Any received message with a lower priority
/// than the one currently set is discarded.
/// An array of `Transport: A transport is a destination bucket for messages.
/// It can be a local file on a disk, a database, or a remote destination service (like an ELK stack or a remote socket connection).
/// Glider offers a broad set of built-in transport, but you are free to create a new implementation to suit your needs.
///
/// ```swift
///    let fileTransport = try FileTransport(fileURL: fileURL, {
///      $0.formatters = [jsonFormatter]
///    })
///
///    let log = Log {
///      $0.subsystem = "com.myawesomeapp"
///      $0.category = "storage"
///      $0.level = .warning
///      $0.transports = [fileTransport, ConsoleTransport()]
///    }
/// ```
///
/// The code above creates a new logger instance that accepts only messages with at least `warning` severity
/// and dispatches them to two different destinations: a local file on disk and a console.
/// To send messages to a logger, call one of the available `write()` functions to the desired severity level:
///
/// ```swift
/// log.error?.write(msg: "An error occurred while proceding to checkout")
/// ```
///
/// The code above send an error message to the logger; the logger itself accept the message because the severity
/// is higher than `warning` severity set.
public class Log: Equatable {
    
    // MARK: - Public Properties
    
    /// Unique identifier of the log instance.
    public let uuid = UUID()
    
    /// Readable log identifier.  
    /// It's a composition of the `subsystem` and `category` properties.
    public private(set) var label: String
    
    /// An emojii representation of the logger instance.
    /// NOTE: Some formatters may use it to better highlights source loggers.
    public private(set) var subsystemIcon: String?
    
    /// Subsystem helps you to track and identify the logger.
    /// Typically this is the bundle identifier of the package which produce the log messages.
    ///
    /// For example you may use `com.myawesomeapp` for a logger
    /// inside the main package of your application.
    public let subsystem: LoggerIdentifiable
    
    /// It's used to further distinguish a logger inside the same `subsystem`.
    ///
    /// For example you may use `network` and `storage` to
    /// separate two loggers in the same package.
    public let category: LoggerIdentifiable
    
    /// Severity level of the log instance.
    /// Any level received by the logger with a lower severity level is automatically ignored.
    public private(set) var level: Level = .debug
    
    /// Temporary disable or enable a logger.
    /// Once disabled a logger refuse any message received regardless their severity.
    public var isEnabled: Bool = true
    
    /// A dictionary with some additional log informations.
    /// Each message sent to the logger ineriths automatically these tags and
    /// can also add/replace existing keys.
    ///
    /// For example you can use it to describe the currently logged user.
    /// Some transports like `GliderSentry` send these tags appropriately to be indexed
    /// by the remote backend service.
    public var tags = Tags()
    
    /// Arbitrary additional information that will be sent with the event.
    /// Values are merged with the current scope and events specific tags.
    public var extra = Metadata()
    
    /// Channel used to send messages with a severity of `emergency`.
    ///
    /// Application/system is unusable.
    public var emergency: Channel? { channels[Level.emergency.rawValue] }
    
    /// Filters allows to eventually discard message received by the logger when it
    /// meets certain criteria.
    ///
    /// You can specify one or multiple rules conforming to the `TransportFilter` protocol;
    /// they will be executed in order and stops when one of them return `false` to the
    /// `shouldAccept()` message.
    public var filters: [TransportFilter] {
        get { transporter.filters }
        set { transporter.filters = newValue }
    }
    
    /// Defines the logger destination bucket where messages are sent once accepted by the logger.
    ///
    /// You can define one or more transport; each transport defines its own rules about storing
    /// or presenting the message. Glider offers a wide list of built-in transport but you can
    /// easily extend this with your own implementation which suits your needs.
    public var transports: [Transport] {
        get { transporter.transports }
        set { transporter.transports = newValue }
    }
    
    // MARK: - Severity Channels
    
    /// Access to the logger's severity channels via subscript.
    /// Any channel below the current severity `level` set has a `nil` channel.
    ///
    /// NOTE:
    /// `nil` channels are a convenient way to avoid using pragma directives to disable
    /// logging in production without worrying about performance issues.
    /// When you disable or set an higher severity level swift runtime automatically
    /// use nil objects to avoid doing any action.
    public subscript(level: Level) -> Channel? {
        channels[level.rawValue]
    }
    
    /// Channel used to send messages with a severity of `trace`.
    public var trace: Channel? { channels[Level.trace.rawValue] }
    
    /// Channel used to send messages with a severity of `debug`.
    ///
    /// Debug messages meant to be useful only during development;
    /// you should disable this level in shipping code.
    public var debug: Channel? { channels[Level.debug.rawValue] }
    
    /// Channel used to send messages with a severity of `info`.
    ///
    /// Informational messages that are not essential for troubleshooting errors.
    /// These can be discarded by the logging system, especially if there are resource constraints.
    public var info: Channel? { channels[Level.info.rawValue] }
    
    /// Channel used to send messages with a severity of `notice`.
    ///
    /// Conditions that are not error conditions, but that may require special handling
    /// or that are likely to lead to an error.
    /// These messages will be stored by the logging system unless it runs out of the storage quota.
    public var notice: Channel? { channels[Level.notice.rawValue] }
    
    /// Channel used to send messages with a severity of `warning`.
    ///
    /// Abnormal conditions that do not prevent the program from completing a specific task.
    /// These are meant to be persisted (unless the system runs out of storage quota).
    public var warning: Channel? { channels[Level.warning.rawValue] }
    
    /// Channel used to send messages with a severity of `error`.
    ///
    /// Describe an error condition.
    public var error: Channel? { channels[Level.error.rawValue] }
    
    /// Channel used to send messages with a severity of `critical`.
    ///
    /// Logging at this level or higher could have a significant performance cost.
    /// The logging system may collect and store enough information such as stack shot etc.
    /// that may help in debugging these critical errors.
    public var critical: Channel? { channels[Level.critical.rawValue] }
    
    /// Channel used to send messages with a severity of `alert`.
    ///
    /// Action must be taken immediately.
    public var alert: Channel? { channels[Level.alert.rawValue] }
    
    // MARK: - Private Properties
    
    /// The low-level interface which manage the dispatch of the log messages to the dispatchers.
    internal let transporter: TransportManager
    
    /// This is the queue used to change the value of the log level safely.
    private let channelsQueue: DispatchQueue
    
    /// Channels are the primary sources which receive messages from log.
    /// All messages are received in order; only some channels are initialized
    /// based upon the current log severity.
    /// Non active channel's related levels are `nil` so the lowest impact is made
    /// on target application.
    internal var channels: [Channel?] = .init(repeating: nil, count: Level.allCases.count)
    
    // MARK: - Initialization
    
    /// Initialize a new logger instance with a configuration object.
    ///
    /// - Parameter config: configuration.
    public init(configuration config: Configuration) {
        self.channelsQueue = DispatchQueue(label: "com.log.channels.\(uuid.uuidString)")

        self.transporter = TransportManager(configuration: config)
        self.isEnabled = config.isEnabled
        self.category = config.category
        self.subsystem = config.subsystem
        self.label = config.label
        self.subsystemIcon = config.subsystemIcon
        setLevel(config.level)
    }
    
    /// Initialize a new logger instance via a callback.
    ///
    /// - Parameter builder: configuration callback.
    public convenience init(_ builder: ((inout Configuration) -> Void)) {
        let config = Configuration(builder)
        self.init(configuration: config)
    }
    
    // MARK: - Public Functions
    
    /// Change the severity level of the log instance.
    ///
    /// Note: Messages sent using a lower level message are ignored automatically.
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
    
    /// Get the first transport instance for a given type.
    ///
    /// - Parameter type: type of transport to get.
    /// - Returns: `T`
    public func transport<T: Transport>(ofType type: T.Type) -> T? {
        for transport in transports {
            if let transport = transport as? T {
                return transport
            }
        }
        return nil
    }
    
    public static func == (lhs: Log, rhs: Log) -> Bool {
        lhs.uuid == rhs.uuid
    }
        
}
