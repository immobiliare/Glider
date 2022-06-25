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

final class LogInterpolationTests: XCTestCase {
    
    // MARK: - Tests
    

    func testRedactionOnDebug() async throws {
        GliderSDK.shared.reset()
        
      let user = LogInterpolationUser(name: "Mark", surname: "Howens", email: "mark.howens@gmail.com", creditCardCVV: 4566)

        let expectedMessages: [String] = [
        //    "Hello \(user.fullName), your email is mark.howens@gmail.com",
        //    "Email set to *******ens@gmail.com",
        //    "CVV is <redacted>",
            "CVV is <redacted>"
        ]
        
        var testIndex = 0
        
        let log = createTestingLog { event in
            print(event.message)
            
            XCTAssertTrue(event.message == expectedMessages[testIndex])
            testIndex += 1
        }
                
      //  log.info?.write("Hello \(user.fullName), your email is \(user.email, privacy: .partiallyHide)")
        
        GliderSDK.shared.disablePrivacyRedaction = false
                
        log.alert?.write(msg: "Email set to \(user.email, privacy: .private)")
      //  log.alert?.write("CVV is \(user.creditCardCVV ?? 0, privacy: .private)")
       // log.alert?.write(msg: "CVV is \(user.creditCardCVV ?? 0, privacy: .private)")
    }
    
    // MARK: - Private Functions
    
    private func createTestingLog(_ onReceiveEvent: @escaping TestTransport.OnReceiveEvent) -> Log {
        let log = Log {
            $0.level = .info
            $0.transports = [
                TestTransport(onReceiveEvent: onReceiveEvent)
            ]
        }
        return log
    }
    
}

// MARK: - Supporting Structures

fileprivate struct LogInterpolationUser {
    var name: String
    var surname: String
    var fullName: String {
        "\(name) \(surname)"
    }
    var email: String
    var creditCardCVV: Int?
}
