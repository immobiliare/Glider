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

public class SizeRotationFileTransport: Transport {
    
    // MARK: - Public Properties
    
    /// Delegate to listen relevant events of the transport layer.
    public weak var delegate: SizeRotationFileTransportDelegate?
    
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
    
    /// URL of the directory with files.
    public var directoryURL: URL
    
    /// Configuration used.
    public let configuration: Configuration
    
    /// Formatters used for data.
    public let formatters: [EventFormatter]
    
    /// URL of the current logging file.
    public var currentFileURL: URL {
        directoryURL
            .appendingPathComponent(configuration.filePrefix)
            .appendingPathExtension(configuration.fileExtension)
    }
    
    // MARK: - Private Properties

    /// Current opened file where the log is happening.
    private var currentFileTransport: FileTransport?
    
    private let fManager = FileManager.default

    // MARK: - Initialization
    
    public init(directoryURL: URL,
                configuration: ((inout Configuration) -> Void),
                formatters: [EventFormatter],
                queue: DispatchQueue? = nil) {
        self.directoryURL = directoryURL
        
        var config = Configuration()
        configuration(&config)
        self.configuration = config
        self.formatters = formatters
        self.queue = queue ?? DispatchQueue(label: String(describing: type(of: self)))
        
        self.currentFileTransport = FileTransport(fileURL: currentFileURL, formatters: formatters)
        self.currentFileTransport?.newlines = config.newLines
    }
    
    // MARK: - Conformance
    
    public func record(event: Event) -> Bool {
        do {
            try rotateFileIfNeeded()
            return currentFileTransport?.record(event: event) ?? false
        } catch {
            return false
        }
    }
    
    // MARK: - Private Functions
    
    /// Check if current logging file is bigger enough to be archived.
    ///
    /// - Throws: throw an exception is something fails.
    /// - Returns: `Bool`, `true` if rotation occurred, `false` otherwise.
    @discardableResult
    private func rotateFileIfNeeded() throws -> Bool {
        guard (currentFileTransport?.size ?? 0) >= configuration.maxFileSize.bytes else {
            return false // maximum file size is not reached, we can still append data
        }
        
        currentFileTransport?.close()
        let archivedFileURL = directoryURL.appendingPathComponent(archivedFilenameFormatter(fileName: configuration.filePrefix))
        try fManager.copyItem(at: currentFileURL, to: archivedFileURL)
        try fManager.removeItem(at: currentFileURL)
        
        delegate?.sizeRotationFileTransport(self,
                                            archivedFileURL: archivedFileURL,
                                            newFileAtURL: currentFileURL)
        
        // Create new file for current logging
        currentFileTransport = FileTransport(fileURL: currentFileURL, formatters: formatters, queue: queue)
        currentFileTransport?.newlines = configuration.newLines
        
        // Remove old files which exceed the count
        if let prunedFileURLs = try removeExceededLogFiles(), !prunedFileURLs.isEmpty {
            delegate?.sizeRotationFileTransport(self, prunedFiles: prunedFileURLs)
        }
        
        return true
    }
    
    /// The function used to produce the name of the single file inside the log directory when
    /// it's archived.
    /// By default it's a function which produce a filename with the following format:
    /// `<filePrefix>_yyyyMMdd'T'HHmmss.SSSZZZZZ_<UUID>.log`
    /// but you can assign your own formatter at inititalization.
    public func archivedFilenameFormatter(fileName: String) -> String {
        let fileExtension = (fileName as NSString).pathExtension
        let filePrefix = (fileName as NSString).deletingPathExtension
        let uuidString = UUID().uuidString.lowercased().trunc(.tail(length: 15))
        let dateString = Date().formatAs("yyyyMMdd'T'HHmmssSSS", timeZone: "GMT")
        let fileSuffix = "\(dateString)-\(uuidString)"
        return "\(filePrefix)\(fileSuffix).\(fileExtension.isEmpty ? ".log" : fileExtension)"
    }
    
    
    /// Remove exceeded log archives based upon the creation date.
    ///
    /// - Throws: throw an exception if something fails.
    /// - Returns: `[URL]` with the URLs of the removed files.
    @discardableResult
    private func removeExceededLogFiles() throws -> [URL]? {
        let archivedFileURLs = try fManager
            .contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            .filter { $0 != currentFileTransport?.fileURL }
        
        guard archivedFileURLs.count > configuration.maxFilesCount else {
            return nil // no needs to remove other files
        }
        
        // Sort files by date
        let sortedArchivedFileURLs = try archivedFileURLs.sorted {
            let creationDate0 = try fManager.attributesOfItem(atPath: $0.path)[.modificationDate] as? Date
            let creationDate1 = try fManager.attributesOfItem(atPath: $1.path)[.modificationDate] as? Date
            return creationDate0!.timeIntervalSince1970 < creationDate1!.timeIntervalSince1970
        }
        
        // Remove expired logs.
        let range = 0 ..< archivedFileURLs.count - Int(configuration.maxFilesCount)
        for index in range {
            try fManager.removeItem(at: sortedArchivedFileURLs[index])
        }
        
        return Array(archivedFileURLs[range])
    }
}

extension SizeRotationFileTransport {
    
    /// Represent the configuration file used to create a new transport.
    public struct Configuration {
        
        /// Maximum size per single file.
        /// By default is set to 10MB.
        var maxFileSize: FileSize = .megabytes(10)
        
        /// Maximum number of files to store.
        /// By default is set to 8.
        var maxFilesCount: Int = 8
        
        /// Filename prefix of each stored file.
        /// By default is set to empty string.
        var filePrefix = ""
        
        /// Extension of single log file.
        /// By default is set to `log`.
        var fileExtension = "log"
        
        /// New lines format for each record.
        var newLines: String = "\n"
        
    }
    
    /// Specify the size of a file.
    public enum FileSize {
        case gigabytes(Int)
        case megabytes(Int)
        case kilobytes(Int)
        case bytes(Int)
        
        internal var bytes: Int64 {
            switch self {
            case .gigabytes(let gb):
                return Int64(pow(1024.0, 3.0)) * Int64(gb)
            case .megabytes(let mb):
                return Int64(pow(1024.0, 2.0)) * Int64(mb)
            case .kilobytes(let kb):
                return Int64(1024 * Int64(kb))
            case .bytes(let b):
                return Int64(Int64(b))
            }
        }
        
    }
    
}

// MARK: - SizeRotationFileTransportDelegate

public protocol SizeRotationFileTransportDelegate: AnyObject {
    
    /// Called when a new file has been created.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - archivedFileURL: archived instance of data.
    ///   - fileURL: new rotated file url (it's always the same name)
    func sizeRotationFileTransport(_ transport: SizeRotationFileTransport,
                                   archivedFileURL: URL?,
                                   newFileAtURL fileURL: URL?)
    
    /// Called when one or more old log files are pruned.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - filesURL: files URLs.
    func sizeRotationFileTransport(_ transport: SizeRotationFileTransport,
                                   prunedFiles filesURL: [URL])
    
}
