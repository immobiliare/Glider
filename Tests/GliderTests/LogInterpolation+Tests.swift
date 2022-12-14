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

import XCTest
@testable import Glider

@available(iOS 13.0.0, tvOS 13.0, *)
final class LogInterpolationTests: XCTestCase {
    
    private let user = LogInterpolationUser(name: "Mark", surname: "Howens", email: "mark.howens@gmail.com", creditCardCVV: 4566)
    private let card = Card(cardIssuer: "Bank Of Monopoly", cardNo: 34553, cardExpireYear: 2022)
    private let myObj = MyNSObject(name: "Me!")

    // MARK: - Tests
    
    /// The following test validate the redaction functions of the logging.
    func testLogRedactions() async throws {
        GliderSDK.shared.reset()
                
        let expectedMessages: [String] = [
            "Hello \(user.fullName), your email is mark.howens@gmail.com",
            "Email is *******ens@gmail.com",
            "CVV is <redacted>",
        ]
        
        var testIndex = 0
        
        let log = createTestingLog(level: .trace, { event, _ in
            print(event.message.content)
            
            XCTAssertEqual(expectedMessages[testIndex], event.message.content)
            testIndex += 1
        })
        
        // This message should be shown in clear because in debug the privacy set is disabled automatically.
        log.info?.write(msg: "Hello \(self.user.fullName), your email is \(self.user.email, privacy: .partiallyHide)")
        
        // Now we force the production behaviour and check if everything is redacted correctly.
        GliderSDK.shared.disablePrivacyRedaction = false
        
        log.alert?.write(msg: "Email is \(self.user.email, privacy: .partiallyHide)")
        log.alert?.write(msg: "CVV is \(self.user.creditCardCVV ?? 0, privacy: .private)")
    }
    
    /// Validate formatting for all supported interpolated formats.
    func testLogInterpolationFormatting() async throws {
        GliderSDK.shared.disablePrivacyRedaction = false
        GliderSDK.shared.locale = Locale(identifier: "en_US")

        let expectedOutput = [
            "Date is 2018-09-12T12:11:00Z",
            "Date is 12.09.18",
            "Date is **09.18",
            "Date is <redacted>",
            "Date is                               2018-09-12T12:11:00Z",
            
            "Float is <redacted>",
            "Float is 45.56",
            "Float is        45.56        ",
            "Float is                45.56",
            "Float is 45.6",
            "There are 45.556km",
            "There are 45 bytes",
            "There are 1 KB",
            "There are 2.1 MB",
            "There are 13345.5534955068",
            "There are $12.00",
            
            "User email is *******ens@gmail.com",
            "User email is *******ens@gmail.com",
            "Value is 10",
            "Value is 00034",
            "Set card Card ID 34553 issued by Bank Of Monopoly expire on 2022",
            "Set card ******************* by Bank Of Monopoly expire on 2022",
            
            "Object is MyNSObject: Me!",
            
            "Value is yes",
            "Value is 1",
            "Value is true",
            "Value is no",
            "Value is 0",
            "Value is false",
            
            "Value is My long st…te anyway",
            "Value is My long st…",
            "Value is …nyway",
            "There are 13345…"
        ]
        
        var testIndex = 0
        let log = createTestingLog(level: .trace, { event, _ in
            print(event.message.content)
            
            XCTAssertEqual(event.message.content, expectedOutput[testIndex], "Expecting \"\(expectedOutput[testIndex])\", got \"\(event.message.content)\"")
            testIndex += 1
        })
        
        // Date
        let date = createDateWithString("09-12-2018 12:11")!
        log.alert?.write(msg: "Date is \(date, format: .iso8601, privacy: .public)")
        log.alert?.write(msg: "Date is \(date, format: .custom("dd.MM.yy"), privacy: .public)")
        log.alert?.write(msg: "Date is \(date, format: .custom("dd.MM.yy"), privacy: .partiallyHide)")
        log.alert?.write(msg: "Date is \(date, format: .iso8601)") // default is private
        log.alert?.write(msg: "Date is \(date, format: .iso8601, pad: .right(columns: 50), privacy: .public)")

        // Float*/
        let float = Float(45.55643)
        log.alert?.write(msg: "Float is \(float, format: .default)") // default is private
        log.alert?.write(msg: "Float is \(float, format: .default, privacy: .public)")
        log.alert?.write(msg: "Float is \(float, format: .default, pad: .center(columns: 20), privacy: .public)")
        log.alert?.write(msg: "Float is \(float, format: .default, pad: .right(columns: 20), privacy: .public)")
        log.alert?.write(msg: "Float is \(float, format: .fixed(precision: 1), privacy: .public)")
        log.alert?.write(msg: "There are \(float, format: .measure(unit: UnitLength.kilometers, options: .providedUnit, style: .short), privacy: .public)")
        log.alert?.write(msg: "There are \(float, format: .bytes(style: .file), privacy: .public)")
        log.alert?.write(msg: "There are \(1024.0, format: .bytes(style: .file), privacy: .public)")
        log.alert?.write(msg: "There are \(2052004.0, format: .bytes(style: .file), privacy: .public)")
        
        let customFormatter = NumberFormatter()
        customFormatter.maximumFractionDigits = 10
        customFormatter.groupingSeparator = "'"
        customFormatter.decimalSeparator = "."
        log.alert?.write(msg: "There are \(13345.5534955068292334, format: .formatter(formatter: customFormatter), privacy: .public)")
        log.alert?.write(msg: "There are \(12.0, format: .currency(symbol: nil, usesGroupingSeparator: true), privacy: .public)")

        // String
        log.alert?.write(msg: "User email is \(self.user.email, pad: .left(columns: 20), privacy: .partiallyHide)")
        log.alert?.write(msg: "User email is \(self.user.email, pad: .center(columns: 5), privacy: .partiallyHide)")

        // Int
        log.alert?.write(msg: "Value is \(10, privacy: .public)")
        log.alert?.write(msg: "Value is \(UInt(34), format: .decimal(minDigits: 5), privacy: .public)")
        
        // CustomStringConvertible
        log.alert?.write(msg: "Set card \(self.card, privacy: .public)")
        log.alert?.write(msg: "Set card \(self.card, privacy: .partiallyHide)")

        // NSObject
        log.alert?.write(msg: "Object is \(self.myObj, privacy: .public)")
        
        // Bool
        log.alert?.write(msg: "Value is \(true, format: .answer, privacy: .public)")
        log.alert?.write(msg: "Value is \(true, format: .numeric, privacy: .public)")
        log.alert?.write(msg: "Value is \(true, format: .truth, privacy: .public)")
        log.alert?.write(msg: "Value is \(false, format: .answer, privacy: .public)")
        log.alert?.write(msg: "Value is \(false, format: .numeric, privacy: .public)")
        log.alert?.write(msg: "Value is \(false, format: .truth, privacy: .public)")
        
        // Truncation
        let someLongString = "My long string is not enough to represent anything but it will truncate anyway"
        log.alert?.write(msg: "Value is \(someLongString, trunc: .middle(length: 20), privacy: .public)")
        log.alert?.write(msg: "Value is \(someLongString, trunc: .tail(length: 10), privacy: .public)")
        log.alert?.write(msg: "Value is \(someLongString, trunc: .head(length: 5), privacy: .public)")
        log.alert?.write(msg: "There are \(13345.5534955068292334, format: .formatter(formatter: customFormatter), trunc: .tail(length: 5), privacy: .public)")

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
    
    private func createDateWithString(_ value: String) -> Date? {
        let format = DateFormatter()
        format.locale = Locale(identifier: "en_US")
        format.timeZone = TimeZone(secondsFromGMT: 0)
        format.dateFormat = "MM-dd-yyyy HH:mm"
        return format.date(from: value)
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

fileprivate struct Card: CustomStringConvertible {
    public var cardIssuer: String
    public var cardNo: Int
    public var cardExpireYear: Int
    
    public var description: String {
        return "Card ID \(cardNo) issued by \(cardIssuer) expire on \(cardExpireYear)"
    }
    
}

fileprivate class MyNSObject: NSObject {
    public var name: String
    
    init(name: String) {
        self.name = name
        super.init()
    }
    
    override var description: String {
        return "MyNSObject: \(name)"
    }
    
}
