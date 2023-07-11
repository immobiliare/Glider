//
//  Glider
//  Fast, Lightweight yet powerful logging system for Swift.
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Authors:
//   - Daniele Margutti <hello@danielemargutti.com>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

/// A `FileTransport` implementation that appends log entries to a file.
///
/// `FileTransport` is a simple log appender that provides no mechanism
/// for file rotation or truncation. Unless you manually manage the log file when
/// a `FileTransport` doesn't have it open, you will end up with an ever-growing
/// file.
/// Use a `SizeRotationFileTransport` instead if you'd rather not have to concern
/// yourself with such details.
open class FileTransport: Transport {
    
    // MARK: - Public Properties
    
    /// The `DispatchQueue` to use for the recorder.
    public var queue: DispatchQueue
    
    /// Transport is enabled.
    public var isEnabled: Bool = true
    
    /// Configuration used to create the transport.
    public let configuration: Configuration
    
    /// Minumum accepted level for this transport.
    /// `nil` means every passing message level is accepted.
    open var minimumAcceptedLevel: Level?
    
    /// Current file size (expressed in bytes).
    public var size: UInt64 {
        fileHandle?.seekToEndOfFile() ?? 0
    }
    
    /// Newline characters, by default `\n` are used.
    open var newlines = "\r\n" {
        didSet {
            self.newLinesData = newlines.data(using: .utf8)
        }
    }
    
    // MARK: - Private Functions
    
    /// New lines data.
    private var newLinesData: Data?
    
    /// Pointer to the file handler.
    private lazy var fileHandle: FileHandle? = {
        FileHandle(forWritingAtPath: configuration.fileURL.path)
    }()
    
    private let handler: UnsafeMutablePointer<FILE>?
    
    // MARK: - Initialization
    
    /// Initialize with configuration.
    ///
    /// - Parameter configuration: configuration.
    public init(configuration: Configuration) throws {
        self.configuration = configuration
        self.isEnabled = configuration.isEnabled
        self.minimumAcceptedLevel = configuration.minimumAcceptedLevel
        
        let fileHandler = fopen(configuration.fileURL.path, "a")
        guard fileHandler != nil else {
            throw GliderError(message: "Failed to open handle for file writing at path: \(configuration.fileURL.path)")
        }
     
        self.queue = configuration.queue
        self.handler = fileHandler
        self.newLinesData = configuration.newlines.data(using: .utf8)
    }
    
    /// Initialize a new `FileTransport` instance to use the given file path
    /// and event formatters. This will fail if `filePath` could not
    /// be opened for writing.
    ///
    /// - Parameters:
    ///   - fileURL: file URL for writing logs.
    ///   - builder: builder to configure additional settings.
    public convenience init(fileURL: URL, _ builder: ((inout Configuration) -> Void)? = nil) throws {
        try self.init(configuration: Configuration(fileURL: fileURL, builder))
    }
    
    deinit {
        // we've implemented FileLogRecorder as a class so we
        // can have a de-initializer to close the file
        close()
    }
    
    // MARK: - Public Functions
    
    open func record(event: Event) -> Bool {
        guard let fileHandle,
              let message = configuration.formatters.format(event: event)?.asData(),
              message.isEmpty == false else {
            return false
        }
        
        if #available(iOS 13.4, macOS 10.15.4, *) {
            do {
                try fileHandle.seekToEnd()
                try fileHandle.write(contentsOf: message as NSData)
                if let newLinesData = newLinesData {
                    try fileHandle.write(contentsOf: newLinesData as NSData)
                }
                
                return true
            } catch {
                return false
            }
        } else {
            // It will still unsafe in case of no left space on disk.
            fileHandle.seekToEndOfFile()
            fileHandle.write(message)
            if let newLinesData = newLinesData {
                fileHandle.write(newLinesData)
            }
            return true

        }
    }
        
    /// Close pointer to file handler.
    open func close() {
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, *) {
            try? fileHandle?.close()
        } else {
            fileHandle?.closeFile()
        }
        fileHandle = nil
    }
    
}

// MARK: - FileTransport.Configuration

extension FileTransport {
    
    /// Represent the configuration settings used to create a new `FileTransport` instance.
    public struct Configuration {
        
        // MARK: - Public Properties
        
        /// Is the transport enabled. By default is set to `true`.
        public var isEnabled = true
        
        /// URL of the local file where the data is stored.
        /// The containing directory must exist and be writable by the process.
        /// If the file does not yet exist, it will be created;
        /// if it does exist, new log messages will be appended to the end of the file.
        public var fileURL: URL
        
        /// Newline characters, by default `\r\n` are used.
        public var newlines = "\r\n"
        
        /// An array of `LogFormatter`s to use for formatting log entries to be
        /// recorded by the receiver. Each formatter is consulted in sequence,
        /// and the formatted string returned by the first formatter to yield a
        /// non-`nil` value will be recorded. If every formatter returns `nil`,
        /// the log entry is silently ignored and not recorded.
        public var formatters: [EventMessageFormatter] = [
            FieldsFormatter.standard()
        ]
        
        /// The `DispatchQueue` to use for the recorder.
        public var queue: DispatchQueue

        /// Minumum accepted level for this transport.
        /// `nil` means every passing message level is accepted.
        public var minimumAcceptedLevel: Level?
        
        // MARK: - Initialization
        
        /// Initialize a new `FileTransport` service.
        ///
        /// - Parameters:
        ///   - fileURL: file url where the data is stored.
        ///   - builder: builder callback to configure additional options.
        public init(fileURL: URL, _ builder: ((inout Configuration) -> Void)?) {
            self.fileURL = fileURL
            self.queue = DispatchQueue(label: String(describing: type(of: self)), attributes: [])
            builder?(&self)
        }
        
    }
    
}
