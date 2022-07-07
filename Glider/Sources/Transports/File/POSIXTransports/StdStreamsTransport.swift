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
    public var queue: DispatchQueue? {
        configuration.queue
    }
    
    /// Configuration settings.
    public let configuration: Configuration
    
    /// Minumum accepted level for this transport.
    /// `nil` means every passing message level is accepted.
    public var minimumAcceptedLevel: Level? = nil
    
    /// Transport is enabled.
    public var isEnabled: Bool = true
    
    // MARK: - Private Properties
    
    /// POSIX stream for standard out messages.
    private var stdoutTransport: POSIXStreamTransport
    
    /// POSIX stream for error messages.
    private var stderrTransport: POSIXStreamTransport
    
    // MARK: - Initialization
    
    /// Initialize with configuration.
    ///
    /// - Parameter configuration: configuration.
    public init(configuration: Configuration) {
        self.configuration = configuration
        self.minimumAcceptedLevel = configuration.minimumAcceptedLevel
                
        self.stdoutTransport = POSIXStreamTransport.stdOut(formatters: configuration.formatters, queue: configuration.queue)
        self.stderrTransport = POSIXStreamTransport.stdErr(formatters: configuration.formatters, queue: configuration.queue)
    }
    
    /// Initialize a new `StdStreamsTransport`.
    ///
    /// - Parameter builder: builder configuration
    public convenience init(_ builder: ((inout Configuration) -> Void)? = nil) {
        self.init(configuration: Configuration(builder))
    }

    // MARK: - Conformance
    
    public func record(event: Event) -> Bool {
        guard isEnabled else { return false }
        
        if event.level.isMoreSevere(than: .info) {
            return stderrTransport.record(event: event)
        } else {
            return stdoutTransport.record(event: event)
        }
    }
    
}

// MARK: - Configuration

extension StdStreamsTransport {
    
    public struct Configuration {
        
        // MARK: - Public Properties
        
        /// Dispatch queue.
        public var queue = DispatchQueue(label: "Glider.\(UUID().uuidString)")

        /// Formatter used to transform a payload into a string.
        /// By default is set to `FieldsFormatter.defaultStdStreamFormatter`.
        public var formatters: [EventFormatter] = [
            FieldsFormatter.defaultStdStreamFormatter()
        ]
        
        /// Minumum accepted level for this transport.
        /// `nil` means every passing message level is accepted.
        public var minimumAcceptedLevel: Level? = nil
        
        // MARK: - Initialization
        
        /// initialize a new `StdStreamsTransport`.
        ///
        /// - Parameter builder: configuration callback.
        public init(_ builder: ((inout Configuration) -> Void)?) {
            builder?(&self)
        }
        
    }
    
}
