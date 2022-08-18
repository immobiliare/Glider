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

/// Transport is where an `Event` is received and stored.
/// A Log instance can have one or more underlying transport services.
/// Glider offers an exhaustive list of built-in transports created explicitly
/// for every need (a local sqlite3 storage, an EKL compatible transport, console transports, and so on).
///
/// A Transport can be any object (typically a class) conforming to the `Transport` protocol.
/// The most important transport function `record()`, which receives a new event and
/// stores/sends it according to its behavior.
public protocol Transport {
    
    // MARK: - Public Properties
    
    /// Queue used to receive the event.
    ///
    /// A serial queue is typically used, such as when the underlying
    /// log facility is inherently single-threaded and/or proper message ordering
    /// wouldn't be ensured otherwise. However, a concurrent queue may also be
    /// used, and might be appropriate when logging to databases or network endpoints.
    ///
    /// You can avoid to use a dispatch queue especially if you are not working with a remote
    /// transporter; in this case use `nil` to receive message from the same queue of the
    /// `TransportManager` instance.
    var queue: DispatchQueue? { get }
    
    /// Allows to disable or enable the transport enabled.
    /// When disabled transport ignore all incoming events to record.
    var isEnabled: Bool { get set }
    
    /// A filter by `severity` implemented at the transport level.
    ///
    /// You can, for example, create a logger which logs in `info` but for one of the transport
    /// (for example ELK or Sentry) it avoids to send messages with a severity lower than `error`
    /// in order to clog your remote service).
    ///
    /// When `nil` the message is not filtered and all messages accepted by the parent `Log` instance
    /// are accepted automatically.
    /// By default is `nil`.
    var minimumAcceptedLevel: Level? { get set }
    
    // MARK: - Public Functions
    
    /// Called by the channel to register a new payload to the given recorder.
    /// The implementation is up to the recorder itself, maybe a rotating file, a database
    /// or a remote web-service.
    ///
    /// - Returns: Bool
    @discardableResult
    func record(event: Event) -> Bool
    
}
