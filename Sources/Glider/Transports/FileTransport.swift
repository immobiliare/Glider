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

/// A `FileTransport` implementation that appends log entries to a file.
///
/// NOTE:
/// `FileTransport` is a simple log appender that provides no mechanism
/// for file rotation or truncation. Unless you manually manage the log file when
/// a `FileLogRecorder` doesn't have it open, you will end up with an ever-growing
/// file.
/// Use a `RotatingLogTrasport` instead if you'd rather not have to concern
/// yourself with such details.
public class FileTransport: Transport {
    
    // MARK: - Public Properties
    
    /// the GCD queue that will be used when executing tasks related to
    /// the receiver.
    /// Log formatting and recording will be performed using this queue.
    ///
    /// A serial queue is typically used, such as when the underlying
    /// log facility is inherently single-threaded and/or proper message ordering
    /// wouldn't be ensured otherwise. However, a concurrent queue may also be
    /// used, and might be appropriate when logging to databases or network
    /// endpoints.
    public var queue: DispatchQueue?
    
    /// Current file size (expressed in bytes).
    public var size: UInt64 {
        fileHandle?.seekToEndOfFile() ?? 0
    }
    
    /// Newline characters, by default `\n` are used.
    public var newlines = "\n" {
        didSet {
            self.newLinesData = newlines.data(using: .utf8)
        }
    }
    
    /// URL of the local file where the data is stored.
    /// The containing directory must exist and be writable by the process.
    /// If the file does not yet exist, it will be created;
    /// if it does exist, new log messages will be appended to the end of the file.
    public let fileURL: URL
    
    /// An array of `LogFormatter`s to use for formatting log entries to be
    /// recorded by the receiver. Each formatter is consulted in sequence,
    /// and the formatted string returned by the first formatter to yield a
    /// non-`nil` value will be recorded. If every formatter returns `nil`,
    /// the log entry is silently ignored and not recorded.
    public let formatters: [EventFormatter]
    
    // MARK: - Private Functions
    
    /// New lines data.
    private var newLinesData: Data?
    
    /// Pointer to the file handler.
    private lazy var fileHandle: FileHandle? = {
        FileHandle(forWritingAtPath: fileURL.path)
    }()
    
    private let handler: UnsafeMutablePointer<FILE>?
    
    // MARK: - Initialization
    
    /// Initialize a new `FileTransport` instance to use the given file path
    /// and event formatters. This will fail if `filePath` could not
    /// be opened for writing.
    ///
    /// - Parameters:
    ///   - fileURL: path of the file to be written (directory must be exists and user
    ///   must have the permissions to write).
    ///   - formatters: formatters used to record the event. If not specified `FieldsFormatter`'s `default()` format isued.
    ///   - queue : The GCD queue that should be used for logging actions related to the receiver.
    public init?(fileURL: URL, formatters: [EventFormatter] = [FieldsFormatter.default()],
                 queue: DispatchQueue? = nil) {
        let fileHandler = fopen(fileURL.path, "a")
        guard fileHandler != nil else {
            return nil
        }
        
        self.queue = queue ?? DispatchQueue(label: String(describing: type(of: self)))
        self.fileURL = fileURL
        self.formatters = formatters
        self.handler = fileHandler
        
        defer {
            self.newlines = "\n"
        }
    }
    
    deinit {
        // we've implemented FileLogRecorder as a class so we
        // can have a de-initializer to close the file
        close()
    }
    
    // MARK: - Public Functions
    
    public func record(event: Event) -> Bool {
        guard let message = formatters.format(event: event)?.asData(),
              message.isEmpty == false else {
            return false
        }
        
        fileHandle?.seekToEndOfFile()
        
        fileHandle?.write(message)
        if let newLinesData = newLinesData {
            fileHandle?.write(newLinesData)
        }

        return true
    }
    
    /// Close pointer to file handler.
    internal func close() {
        try? fileHandle?.close()
        fileHandle = nil
    }
    
}
