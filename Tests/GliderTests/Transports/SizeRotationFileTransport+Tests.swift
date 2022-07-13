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

import XCTest
@testable import Glider
import SwiftUI

final class SizeRotationTransportTests: XCTestCase, SizeRotationFileTransportDelegate {
    
    private var prunedFiles = 0
    private var filesCount = 0
    
    override func setUp() {
        super.setUp()
        
        self.prunedFiles = 0
        self.filesCount = 0
    }
        
    func test_sizeRotationFileTransport() async throws {
        guard let directoryURL = try URL.newDirectoryURL() else {
            XCTFail()
            return
        }
        
        let maxFileSize = SizeRotationFileTransport.FileSize.kilobytes(100)
        let maxFileCount = 4
        let filePrefix = "mylog_"
        
        let sizeLogTransport = try SizeRotationFileTransport(directoryURL: directoryURL) {
            $0.maxFilesCount = maxFileCount
            $0.maxFileSize = maxFileSize
            $0.filePrefix = filePrefix
            $0.formatters = [JSONFormatter.default()]
            $0.delegate = self
        }
        
        let log = Log {
            $0.level = .trace
            $0.transports = [sizeLogTransport]
        }
        
        for i in 0..<10000 {
            log.info?.write({
                $0.message = "test message \(i, privacy: .public)!"
                $0.extra = ["index": "\(i)"]
            })
        }
        
        print("Pruned \(prunedFiles), count: \(filesCount)")
        
        // Check written filex
        let writtenFileURLs = try FileManager.default.contentsOfDirectory(atPath: directoryURL.path).map {
            directoryURL.appendingPathComponent($0)
        }
        
        let variationPercentage = 0.05 // 5% in sizes
        let maxSizeAccepted = maxFileSize.bytes + Int64(round(variationPercentage * Double(maxFileSize.bytes)))
        
        for fileURL in writtenFileURLs {
            // Validate maximum size
            let attr = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let fileSize = attr[.size] as! Int64
            XCTAssertTrue(fileSize <= maxSizeAccepted)
            XCTAssertTrue(fileSize > 0)

            // Validate the existence of the prefix
            XCTAssertTrue(fileURL.lastPathComponent.contains(filePrefix))
            XCTAssertTrue(fileURL.pathExtension == sizeLogTransport.configuration.fileExtension)
        }
        
        print("Written files: \(writtenFileURLs.count) (max=\(maxFileCount + 1)")
        
        XCTAssertTrue(writtenFileURLs.count <= (maxFileCount + 1))
        XCTAssertTrue(prunedFiles > 4)
    }
    
    // MARK: - Delegate
    
    func sizeRotationFileTransport(_ transport: SizeRotationFileTransport, prunedFiles filesURL: [URL]) {
        prunedFiles += 1
    }
    
    func sizeRotationFileTransport(_ transport: SizeRotationFileTransport, archivedFileURL: URL?, newFileAtURL fileURL: URL?) {
        filesCount += 1
    }
    
}
