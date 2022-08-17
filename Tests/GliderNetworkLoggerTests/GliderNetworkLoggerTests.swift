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
@testable import GliderNetworkLogger

final class GliderNetworkLoggerTests: XCTestCase {
    
    func test_captureNetworkTraffic() async throws {
        let exp = expectation(description: "test")

        NetworkLogger.shared.captureGlobally(true)
        
        let url = URL(string: "http://www.stackoverflow.com")!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            print(String(data: data, encoding: .utf8)!)
        }

        task.resume()
        
        wait(for: [exp], timeout: 120)

        NetworkLogger.shared.captureGlobally(false)
        
    }
    
}
