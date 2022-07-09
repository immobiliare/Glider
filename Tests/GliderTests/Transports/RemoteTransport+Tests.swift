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

final class RemoteTransportTests: XCTestCase {
    
    func test_remoteTransport() async throws {
        
        let exp = expectation(description: "")

        let remoteTransport = try RemoteTransport(serviceType: "_pulse._tcp", delegate: nil)
        let log = Log {
            $0.transports = [
                remoteTransport
            ]
        }
        
        log.info?.write(msg: "Ciao")
        wait(for: [exp], timeout: 60)
        
    }
    
}
