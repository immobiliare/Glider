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
import Glider

/// An `Event` extension to convert an `Event` to a logstash compatible body.
extension Event {
    
    /// A struct used to encode the `Logger.Level`, `Logger.Message`, `Logger.Metadata`, and a timestamp
    /// which is then sent to Logstash
    fileprivate struct LogstashHTTPBody: Codable {
        let timestamp: String
        let label: String
        let loglevel: Level
        let message: Message
        let metadata: Metadata
    }
    
    /// Provide encoding of the event into `Data` object.
    /// - Parameter event: event to convert.
    /// - Returns: `Data?`
    internal func encodeToLogstashFormat(_ jsonEncoder: JSONEncoder) -> Data? {
        let bodyObject = LogstashHTTPBody(
            timestamp: timestamp,
            label: label,
            loglevel: level,
            message: message,
            metadata: extra ?? [:]
        )
        
        return try? jsonEncoder.encode(bodyObject)
    }
    
    // MARK: - Private Functions
    
    /// Uses the `ISO8601DateFormatter` to create the timstamp of the log entry
    private var timestamp: String {
        Self.dateFormatter.string(from: Date())
    }
    
    private var label: String {
        [subsystem, category].compactMap({ $0 }).joined(separator: ".")
    }

    /// An `ISO8601DateFormatter` used to format the timestamp of the log entry in an ISO8601 conformant fashion
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        // The identifier en_US_POSIX leads to exception on Linux machines,
        // on Darwin this is apperently ignored (it's even possible to state an
        // arbitrary value, no exception is thrown on Darwin machines -> inconsistency?)
        //formatter.timeZone = TimeZone(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.autoupdatingCurrent
        return formatter
    }()
    
}
