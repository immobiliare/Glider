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

final class StdStreamTransportTests: XCTestCase {
    
    /// The following test check if `FileLogTransport` transport layer.
    func test_stdTransport() {        
        let stdTransport = StdStreamTransport()
        
        let log = Log {
            $0.level = .debug
            $0.transports = [stdTransport]
        }
        
        for i in 0..<100 {
            log.info?.write(event: {
                $0.message = "test message \(i)!"
                $0.extra = ["index": "\(i)"]
            })
        }
        
    }
    
}
