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

import XCTest
@testable import Glider
@testable import GliderNetWatcher

final class GliderNetworkLoggerTests: XCTestCase {
    
    func test_captureNetworkTraffic() async throws {
        let exp = expectation(description: "test")
        
       // let archiveURL = URL(fileURLWithPath: "/Users/daniele/Desktop/test.sqlite")
       // let archiveConfig = NetArchiveTransport.Configuration(location: .fileURL(archiveURL))
        
        let diURL = URL(fileURLWithPath: "/Users/daniele/Desktop/store")
        let sparseConfig = NetSparseFilesTransport.Configuration(directoryURL: diURL)
        
        //let config = try NetWatcher.Config(storage: .archive(archiveConfig))
        let config = try NetWatcher.Config(storage: .sparseFiles(sparseConfig))

        
        NetWatcher.shared.setConfiguration(config)
        NetWatcher.shared.captureGlobally(true)

        for i in 0..<100 {
        let url = URL(string: "https://github.com/malcommac/Glider")!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            print("Done!")
        }

        task.resume()
        }
        
        wait(for: [exp], timeout: 120)

        NetWatcher.shared.captureGlobally(false)
        
    }
    
}
