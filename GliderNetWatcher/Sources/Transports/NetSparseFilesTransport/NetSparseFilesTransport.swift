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
import Glider

/// The `NetSparseFilesTransport` class is used to store network activity
/// inside a root folder.
///
/// Each call is stored with a single textual file
/// with the id of the network call and its creation date set to the origin call date.
/// Inside each file you can found `<cURL command for request>\n\n<raw response data>`.
public class NetSparseFilesTransport: Transport {
    
    // MARK: - Public Properties
    
    /// The `DispatchQueue` to use for the recorder.
    public var queue: DispatchQueue
    
    /// Configuration used for this transport.
    public let configuration: Configuration
    
    /// Is logging service enabled.
    public var isEnabled: Bool = true
    
    /// Ignored for this kind of transport.
    public var minimumAcceptedLevel: Level? = nil
    
    // MARK: - Private Properties
    
    /// FileManager instance.
    private let fManager = FileManager.default
    
    /// New lines separator.
    private static let newLines = "\n\n"
    
    // MARK: - Initialization
    
    /// Initialize a new database transport for network events with a given configuration.
    ///
    /// - Parameter configuration: configuration.
    public init(configuration: Configuration) throws {
        self.configuration = configuration
        self.isEnabled = configuration.isEnabled
        self.queue = configuration.queue
        
        var isDirectory = ObjCBool(false)
        if fManager.fileExists(atPath: configuration.directoryURL.path, isDirectory: &isDirectory) == false {
            if configuration.resetAtStartup {
                try fManager.removeItem(at: configuration.directoryURL)
            }

            try fManager.createDirectory(at: configuration.directoryURL, withIntermediateDirectories: false)
        }
    }
    
    // MARK: - Protocol Conformance
    
    public func record(event: Event) -> Bool {
        do {
            guard let networkEvent = event.object as? NetworkEvent else {
                return false
            }
            
            let fullURL = configuration.directoryURL.appendingPathComponent("\(networkEvent.id).txt")
            if fManager.fileExists(atPath: fullURL.path) {
                try fManager.removeItem(at: fullURL)
            }
            
            fManager.createFile(atPath: fullURL.path, contents: nil, attributes: [
                .creationDate: networkEvent.startDate
            ])
            
            let fileHandle = FileHandle(forWritingAtPath: fullURL.path)
            fileHandle?.seekToEndOfFile()

            // Section 1: cURL command for request
            if let curlCommand = networkEvent.urlRequest?.cURLCommand() {
                fileHandle?.write(curlCommand.asData()!)
            }

            // Separator
            fileHandle?.write(Self.newLines.asData()!)

            // Section 2: Complete raw data
            if let data = networkEvent.responseData {
                fileHandle?.write(data)
            } else if let error = networkEvent.responseErrorDescription {
                fileHandle?.write(error.asData()!)
            }
            
            try? fileHandle?.close()
            return true
        } catch {
            return false
        }
    }
    
}
