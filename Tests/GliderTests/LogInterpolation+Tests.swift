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
    
    /// The following test validate the redaction functions of the logging.
    func testLogRedactions() async throws {
        GliderSDK.shared.reset()
        
        let user = LogInterpolationUser(name: "Mark", surname: "Howens", email: "mark.howens@gmail.com", creditCardCVV: 4566)
        
        let expectedMessages: [String] = [
            "Hello \(user.fullName), your email is mark.howens@gmail.com",
            "Email is *******ens@gmail.com",
            "CVV is <redacted>",
        ]
        
        var testIndex = 0
        
        let log = createTestingLog(level: .trace, { event in
            print(event.message.content)
            
            XCTAssertEqual(expectedMessages[testIndex], event.message.content)
            testIndex += 1
        })
        
        // This message should be shown in clear because in debug the privacy set is disabled automatically.
        log.info?.write(msg: "Hello \(user.fullName), your email is \(user.email, privacy: .partiallyHide)")
        
        // Now we force the production behaviour and check if everything is redacted correctly.
        GliderSDK.shared.disablePrivacyRedaction = false
        
        log.alert?.write(msg: "Email is \(user.email, privacy: .partiallyHide)")
        log.alert?.write(msg: "CVV is \(user.creditCardCVV ?? 0, privacy: .private)")
    }
    
    func testLogInterpolationFormatting() async throws {
        
    }
    
    // MARK: - Private Functions
    
    private func createTestingLog(level: Level = .info, _ onReceiveEvent: @escaping TestTransport.OnReceiveEvent) -> Log {
        let log = Log {
            $0.level = level
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
