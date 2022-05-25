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

/// This transport  output that can output text messages to POSIX streams.
public class StdStreamTransport: Transport {
    
    // MARK: - Public Properties
    
    /// Dispatch queue.
    public var queue: DispatchQueue?
    
    /// Formatter used to transform a payload into a string.
    public var formatters: [EventFormatter]
    
    /// POSIX strema used as output.
    public let stream: UnsafeMutablePointer<FILE>
    
    // MARK: - Initialization
    
    public init(stream: UnsafeMutablePointer<FILE> = Darwin.stdout,
                formatters: [EventFormatter] = [FieldsFormatter.defaultStdStreamFormatter()],
                queue: DispatchQueue? = nil) {
        self.stream = stream
        self.formatters = formatters
        self.queue = queue ?? DispatchQueue(label: String(describing: type(of: self)))
    }
    
    // MARK: - Conformance
    
    public func record(event: Event) -> Bool {
        guard let message = formatters.format(event: event)?.asString(),
              message.isEmpty == false else {
            return false
        }
        
        return fputs(message + "\n", stream) != EOF
    }
    
}

extension FieldsFormatter {
    
    /// Instantiate a new formatter for payload which will be recorder on a file or console.
    ///
    /// - Returns: `FieldPayloadFormatter`
    public static func defaultStdStreamFormatter() -> FieldsFormatter {
        let fields: [FieldsFormatter.Field] = [
            .timestamp(style: .iso8601, {
                $0.padding = .right(columns: 20)
            }),
            .delimiter(style: .spacedPipe),
            .level(style: .short, {
                $0.padding = .left(columns: 3)
            }),
            .literal(" "),
            .message()
        ]
        return FieldsFormatter(fields: fields)
    }
    
}
