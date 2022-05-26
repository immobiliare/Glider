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
import Darwin.C.stdio

/// The `StdStreamsTransport` is a transport that writes log events
/// to either the standard output stream ("`stdout`") or the standard error stream
/// ("`stderr`") of the running process.
///
/// Messages are directed to the appropriate stream depending on the `severity`
/// property of the `LogEntry` being recorded.
///
/// Messages having a severity of `.verbose`, `.debug` and `.info` will be
/// directed to `stdout`, while those with a severity of `.warning` and `.error`
/// are directed to `stderr`.
public class StdStreamsTransport: Transport {
    
    // MARK: - Public Properties
    
    /// Dispatch queue.
    public var queue: DispatchQueue?
    
    /// Formatter used to transform a payload into a string.
    public var formatters: [EventFormatter]
    
    // MARK: - Private Properties
    
    /// POSIX stream for standard out messages.
    private var stdoutTransport: POSIXStreamTransport
    
    /// POSIX stream for error messages.
    private var stderrTransport: POSIXStreamTransport
    
    // MARK: - Initialization
    
    public init(formatters: [EventFormatter] = [FieldsFormatter.defaultStdStreamFormatter()],
                queue: DispatchQueue? = nil) {
        self.queue = queue ?? DispatchQueue(label: String(describing: type(of: self)))
        self.formatters = formatters
        self.stderrTransport = POSIXStreamTransport(stream: stderr, formatters: formatters, queue: self.queue)
        self.stdoutTransport = POSIXStreamTransport(stream: stdout, formatters: formatters, queue: self.queue)
    }

    // MARK: - Conformance
    
    public func record(event: Event) -> Bool {
        if event.level.isMoreSevere(than: .info) {
            return stderrTransport.record(event: event)
        } else {
            return stdoutTransport.record(event: event)
        }
    }
    
}
