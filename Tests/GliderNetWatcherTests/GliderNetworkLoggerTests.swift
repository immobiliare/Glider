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

import XCTest
@testable import Glider
@testable import GliderNetWatcher

final class GliderNetworkLoggerTests: XCTestCase, NetWatcherDelegate {
    
    private let testURLs = (1...10).map {
        URL(string: "https://jsonplaceholder.typicode.com/posts/\($0)")!
    }
    
    /*func test_captureNetworkTraffic_archiveFile() async throws {
        let archiveURL = URL(fileURLWithPath: "/Users/daniele/Desktop/test.sqlite")
        let archiveConfig = NetArchiveTransport.Configuration(location: .fileURL(archiveURL))
    }*/
    
    func test_captureNetworkTraffic_sparseFiles() async throws {
        let downloadExp = expectation(description: "test")
        var downloadedCount = 0
        
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let folderURL = temporaryDirectoryURL.appendingPathComponent("network_events_store")
        try FileManager.default.removeItem(at: folderURL)
        
        let sparseConfig = NetSparseFilesTransport.Configuration(directoryURL: folderURL)
        let watcherConfig = try NetWatcher.Config(storage: .sparseFiles(sparseConfig))
        
        print("Saving reports to \(folderURL.path)")
        
        NetWatcher.shared.setConfiguration(watcherConfig)
        NetWatcher.shared.captureGlobally(true)
        NetWatcher.shared.delegate = self

        for url in testURLs {
            print("Sending request for \(url.absoluteString)...")
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                downloadedCount += 1
                if downloadedCount == self.testURLs.count {
                    downloadExp.fulfill()
                }
            }
            task.resume()
        }
        
        wait(for: [downloadExp], timeout: 120)

        NetWatcher.shared.captureGlobally(false)
    }
    
    func netWatcher(_ watcher: NetWatcher, didCaptureEvent event: NetworkEvent) {
        print("Captured new request to \(event.url.absoluteString) with \(event.httpResponse?.statusCode ?? 0)")
    }
    
    func netWatcher(_ watcher: NetWatcher, shouldRecordRequest request: URLRequest) -> Bool {
        let id = Int(request.url!.lastPathComponent)!
        return id % 2 == 0
    }
    
    func netWatcher(_ watcher: NetWatcher, didIgnoreRequest request: URLRequest) {
        let id = Int(request.url!.lastPathComponent)!
        XCTAssertTrue(id % 2 != 0, "Only non odd request should be ignored")
    }
    
}
