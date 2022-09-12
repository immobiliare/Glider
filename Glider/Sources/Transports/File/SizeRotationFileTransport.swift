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

/// `SizeRotationFileTransport` maintains a set of daily rotating log
/// files, kept for a user-specified number of days.
///
/// `SizeRotationFileTransport` instance assumes full control over
/// the log directory specified by its `directoryPath` property.
/// Please see the configuration documentation for details.
public class SizeRotationFileTransport: Transport {
    
    // MARK: - Public Properties
    
    /// Delegate to listen relevant events of the transport layer.
    public weak var delegate: SizeRotationFileTransportDelegate?
    
    /// The `DispatchQueue` to use for the recorder.
    public var queue: DispatchQueue
    
    /// Transport is enabled.
    public var isEnabled: Bool = true
    
    /// Configuration used to create the transport.
    public let configuration: Configuration
    
    /// Minumum accepted level for this transport.
    /// `nil` means every passing message level is accepted.
    public var minimumAcceptedLevel: Level?
    
    /// URL of the current logging file.
    public var currentFileURL: URL {
        configuration.directoryURL
            .appendingPathComponent(configuration.filePrefix)
            .appendingPathExtension(configuration.fileExtension)
    }
    
    // MARK: - Private Properties

    /// Current opened file where the log is happening.
    private var currentFileTransport: FileTransport?
    
    /// FileManager instance.
    private let fManager = FileManager.default

    // MARK: - Initialization
    
    /// Initialize a new `SizeRotationFileTransport` with configuration.
    ///
    /// - Parameter configuration: configuration.
    public init(configuration: Configuration) throws {
        self.configuration = configuration
        self.isEnabled = configuration.isEnabled
        
        var isDirectory = ObjCBool(false)
        if fManager.fileExists(atPath: configuration.directoryURL.path, isDirectory: &isDirectory) == false {
            try fManager.createDirectory(at: configuration.directoryURL, withIntermediateDirectories: false)
        }
        
        self.minimumAcceptedLevel = configuration.minimumAcceptedLevel
        self.queue = configuration.queue
        self.delegate = configuration.delegate
        
        self.currentFileTransport = try FileTransport(fileURL: currentFileURL, {
            $0.formatters = self.configuration.formatters
        })
        self.currentFileTransport?.newlines = configuration.newLines
    }
    
    /// Initialize a new `SizeRotationFileTransport` instance with given configuration callback.
    ///
    /// - Parameters:
    ///   - directoryURL: directory url. If not available it will be created automatically.
    ///   - builder: builder function to setup additional settings.
    public convenience init(directoryURL: URL, _ builder: ((inout Configuration) -> Void)? = nil) throws {
        try self.init(configuration: Configuration(directoryURL: directoryURL, builder))
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
        let archivedFileURL = configuration.directoryURL.appendingPathComponent(archivedFilenameFormatter(fileName: configuration.filePrefix))
        try fManager.copyItem(at: currentFileURL, to: archivedFileURL)
        try fManager.removeItem(at: currentFileURL)
        
        delegate?.sizeRotationFileTransport(self,
                                            archivedFileURL: archivedFileURL,
                                            newFileAtURL: currentFileURL)
        
        // Create new file for current logging
        currentFileTransport = try FileTransport(fileURL: currentFileURL, {
            $0.formatters = self.configuration.formatters
            $0.queue = self.configuration.queue
            $0.newlines = self.configuration.newLines
        })
        
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
            .contentsOfDirectory(at: configuration.directoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            .filter { $0 != currentFileTransport?.configuration.fileURL }
        
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
    
    /// Represent the configuration settings used to create a new `SizeRotationFileTransport` instance.
    public struct Configuration {
        
        // MARK: - Public Properties
        
        /// Is the transport enabled. By default is set to `true`.
        public var isEnabled = true
        
        /// Delegate to listen relevant events of the transport layer.
        public weak var delegate: SizeRotationFileTransportDelegate?
        
        /// The `DispatchQueue` to use for the recorder.
        public var queue: DispatchQueue

        /// URL of the directory with files.
        public var directoryURL: URL
        
        /// Formatters used for data.
        public var formatters: [EventMessageFormatter] = [
            FieldsFormatter.standard()
        ]
        
        /// Maximum size per single file.
        /// By default is set to 10MB.
        public var maxFileSize: FileSize = .megabytes(10)
        
        /// Maximum number of files to store.
        /// By default is set to 8.
        public var maxFilesCount: Int = 8
        
        /// Filename prefix of each stored file.
        /// By default is set to empty string.
        public var filePrefix = ""
        
        /// Extension of single log file.
        /// By default is set to `log`.
        public var fileExtension = "log"
        
        /// New lines format for each record.
        public var newLines: String = "\n"
        
        /// Minumum accepted level for this transport.
        /// `nil` means every passing message level is accepted.
        public var minimumAcceptedLevel: Level?
        
        // MARK: - Initialization
        
        /// Initialize a new configuration for an SizeRotationFileTransport transport.
        ///
        /// - Parameters:
        ///   - directoryURL: directory url where logs are saved.
        ///   - builder: builder configuration to setup additional settings.
        public init(directoryURL: URL, _ builder: ((inout Configuration) -> Void)?) {
            self.directoryURL = directoryURL
            self.queue = DispatchQueue(label: String(describing: type(of: self)), attributes: [])
            builder?(&self)
        }
        
    }
    
}

// MARK: - FileSize

extension SizeRotationFileTransport {
    
    /// Specify the size of a file.
    public enum FileSize {
        /// gigabytes unit
        case gigabytes(Int)
        /// megabytes unit
        case megabytes(Int)
        /// kilobytes unit
        case kilobytes(Int)
        /// bytes unit
        case bytes(Int)
        
        /// Return the bytes converted value.
        internal var bytes: Int64 {
            switch self {
            case .gigabytes(let value):
                return Int64(pow(1024.0, 3.0)) * Int64(value)
            case .megabytes(let value):
                return Int64(pow(1024.0, 2.0)) * Int64(value)
            case .kilobytes(let value):
                return Int64(1024 * Int64(value))
            case .bytes(let value):
                return Int64(Int64(value))
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
