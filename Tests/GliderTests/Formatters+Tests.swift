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

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#endif

import XCTest
@testable import Glider

final class FormattersTest: XCTestCase {
    
    func test_terminalFormatter2() throws {
        let formatter = FieldsFormatter(fields: [
            .label({
                $0.stringFormat = "[%@]"
            })
        ])
        
        let consoleTransport = TestTransport(formatters: [formatter], onReceiveEvent: { _, msg in
            print(msg)
        })
        
        let log = Log {
            $0.subsystem = "com.indomionetwork"
            $0.category = "general"
            $0.level = .trace
            $0.transports = [
                consoleTransport
            ]
        }

        log.info?.write(msg: "Some event happened!")
    }
    
    /// Test the output of the formatter for colored consoles.
    func test_terminalFormatter() throws {
        let eventsToPrint = 100
        
        let outputFileURL = URL.temporaryFileURL(fileName: "output-log", fileExtension: "log", removeIfExists: true)
        let formatter = TerminalFormatter(colorize: .all, colorizeFields: [.level, .message])
        let fileTransport = try FileTransport(fileURL: outputFileURL) {
            $0.formatters = [formatter]
        }

        let xcodeFormatter = XCodeFormatter(showCallSite: false, colorize: .none, colorizeFields: [])
        let consoleTransport = TestTransport(formatters: [xcodeFormatter], onReceiveEvent: { _, msg in
            print(msg)
        })
        
        let log = Log {
            $0.level = .trace
            $0.transports = [
                consoleTransport,
                fileTransport
            ]
        }
        
        for i in 0..<eventsToPrint {
            let level = Level.allCases.randomElement() ?? .debug
            log[level]?.write(msg: "Some event happened \(i)!")
        }
        
        let readFileLines = try String(contentsOf: outputFileURL, encoding: .ascii)
            .components(separatedBy: "\r\n")
            .filter({ $0.isEmpty == false })
        XCTAssertEqual(readFileLines.count, eventsToPrint)
        
        let isoFormatter = ISO8601DateFormatter()
        
        for line in readFileLines {
            guard let space = line.firstIndex(of: " ") else {
                XCTFail()
                return
            }
            let date = String(line[line.startIndex..<space])
            XCTAssertNotNil(isoFormatter.date(from: date))
            
            let text = String(line[space...]).trimmingCharacters(in: .whitespacesAndNewlines)
            var messageText = ""
            
            if let range = text.range(of: "] ") {
                messageText = String(text[range.upperBound...])
            }

            XCTAssertEqual("\u{1B}", text[0])
            XCTAssertEqual("\u{1B}", messageText[0..<1])
            
            var colorCode = ""
            
            if text.contains("[INFO]") {
                colorCode = "36"
            } else if text.contains("[ERROR]") {
                colorCode = "31"
            } else if text.contains("[WARNING]") {
                colorCode = "35"
            } else if text.contains("[TRACE]") {
                colorCode = "32"
            } else if text.contains("[NOTICE]") {
                colorCode = "35"
            } else if text.contains("[ALERT]") {
                colorCode = "31"
            } else if text.contains("[EMERGENCY]") {
                colorCode = "31"
            } else if text.contains("[DEBUG]") {
                colorCode = "36"
            } else if text.contains("[CRITICAL]") {
                colorCode = "31"
            } else {
                XCTFail("Unexpected message")
            }
            
            XCTAssertEqual(text[1..<6], "[\(colorCode)m[")
            XCTAssertEqual(messageText[1..<9], "[0m\u{1B}[\(colorCode)m")
            XCTAssertEqual(messageText[messageText.count-3..<messageText.count], "[0m")
        }
        
    }
    
    /// Test the `XCodeFormatter` to format colorized/non colorized messages into the IDE debug console.
    func test_xCodeColorized() throws {
        let formatter = XCodeFormatter(showCallSite: true,
                                       colorize: .onlyImportant,
                                       colorizeFields: [.level, .message])
        let transport = TestTransport(formatters: [formatter], onReceiveEvent: { _, msg in
            print(msg)
        })
        
        let log = Log {
            $0.subsystem = "com.indomionetwork"
            $0.category = "general"
            $0.subsystemIcon = "🌎"
            $0.transports = [transport]
        }
        
        log.error?.write(msg: "Some error has occurred")
    }
    
    /// The following test check the default formatter used for console.
    func test_logFormattingStandardWithIcon() throws {
        let expectedMsgs = [
            "[🌎:general] 🔵 Hello guys",
            "[com.indomionetwork:general] INFO Hello guys",
            "[🌎:general] INFO Hello guys",
            "[com.indomionetwork:general] INFO Hello guys"
        ]
        
        var indexToCheck = 0
        
        let transport = TestTransport(formatters: [FieldsFormatter.standard(useSubsystemIcon: true)], onReceiveEvent: { _, msg in
            print(msg)
            XCTAssertTrue(msg.contains(expectedMsgs[indexToCheck]))
            indexToCheck += 1
        })
        
        
        let log = Log {
            $0.subsystem = "com.indomionetwork"
            $0.category = "general"
            $0.subsystemIcon = "🌎"
            $0.transports = [transport]
        }
        
        log.info?.write(msg: "Hello guys")
        transport.formatters = [FieldsFormatter.standard(useSubsystemIcon: false, severityIcon: false)]
        log.info?.write(msg: "Hello guys")
        transport.formatters = [FieldsFormatter.standard(useSubsystemIcon: true, severityIcon: false)]
        log.info?.write(msg: "Hello guys")
        transport.formatters = [FieldsFormatter.standard(useSubsystemIcon: false, severityIcon: false)]
        log.info?.write(msg: "Hello guys")
    }
    
    func test_extraFieldListFormatting() throws {
        createTestWithExtraFormattingOfType(.list) { _, message in
            XCTAssertTrue(message.contains("extra={\n\t- key1=\"a_simple_value\"\n\t- key2=\"another_value\"\n}"))
        }
    }
    
    func test_extraFieldQueryStringFormatting() throws {
        createTestWithExtraFormattingOfType(.queryString) { _, message in
            XCTAssertTrue(message.contains("""
            key1=a_simple_value&key2=another_value
            """))
        }
    }
    
    func test_extraFieldsTableFormatting() throws {
        createTestWithExtraFormattingOfType(.table) { _, message in
            XCTAssertTrue(message.contains("""
            ┌───────┬────────────────┐
            │ EXTRA │ VALUE          │
            ├───────┼────────────────┤
            │ key1  │ a_simple_value │
            │ key2  │ another_value  │
            └───────┴────────────────┘
            """))
        }
    }
    
    func test_xcodeLogFormatter() throws {
        let xcodeFormatter = XCodeFormatter()
        
        let console = ConsoleTransport {
            $0.formatters = [xcodeFormatter]
        }
        
        let log = Log {
            $0.level = .trace
            $0.transports = [console]
        }
        
        for i in 0..<100 {
            let level: Level = Level.allCases.randomElement() ?? .info
            log[level]?.write(msg: "Event message \(i)", extra: ["extra1": "val"], tags: ["tag1": "val1"])
        }
        
    }
    
    func test_sysLogFormatter() throws {
        let fileURL = URL.temporaryFileURL()

        let sysLog = SysLogFormatter(hostname: "myhost", extraFields: [.callingThread(style: .integer), .eventUUID()])
        let fileTransport = try FileTransport(fileURL: fileURL, {
            $0.formatters = [sysLog]
        })
        
        let log = Log {
            $0.level = .trace
            $0.transports = [fileTransport]
        }
        
        log.error?.write(msg: "Event message", extra: ["extra1": "val"], tags: ["tag1": "val1"])
    }
    
    /// Test the MsgPack formatter.
    func test_msgPackFormatter() throws {
        let fileURL = URL.temporaryFileURL()

        let msgPack = MsgPackFormatter.standard()
        let fileTransport = try FileTransport(fileURL: fileURL, {
            $0.formatters = [msgPack]
        })
        
        let log = Log {
            $0.level = .trace
            $0.transports = [fileTransport]
        }
        
        let object = UserTest(name: "Mark", surname: "Snow", age: 33)
        log.error?.write(msg: "Event message", object: object, extra: ["extra1": "val"], tags: ["tag1": "val1"])
        
        guard let writtenData = try? Data(contentsOf: fileURL) else {
            XCTFail()
            return
        }
        
        var decodedData = MessagePackReader(from: writtenData)
        let payload = try decodedData.readDictionary()
        
        // Check main data
        let message: String? = payload.valueAtKeyPath("message")
        XCTAssertEqual(message, "Event message")

        let level: String? = payload.valueAtKeyPath("level")
        XCTAssertEqual(level, "3")

        // Check object
        let rawObjectData: Data? = payload.valueAtKeyPath("object")
        let decodedUser = try JSONDecoder().decode(UserTest.self, from: rawObjectData!)
        XCTAssertNotNil(decodedUser)
        XCTAssertEqual(decodedUser.name, "Mark")
        XCTAssertEqual(decodedUser.age, 33)
        
        // Check extra
        let extraValue: String? = payload.valueAtKeyPath("extra.extra1")
        XCTAssertEqual(extraValue, "val")

        // Check tags
        let tagsValue: String? = payload.valueAtKeyPath("tags.tag1")
        XCTAssertEqual(tagsValue, "val1")
    }
    
    /// This tests check the `JSONFormatter`.
    func test_jsonFormatter() throws {
        let fileURL = URL.temporaryFileURL()

        let jsonFormatter = JSONFormatter.standard()
        let fileTransport = try FileTransport(fileURL: fileURL, {
            $0.formatters = [jsonFormatter]
        })
        
        let log = Log {
            $0.level = .trace
            $0.transports = [fileTransport]
        }
        
        GliderSDK.shared.scope.tags = ["globalTag": "valueTag"]
        GliderSDK.shared.scope.extra = ["globalExtra": "valueExtra"]

        let object = UserTest(name: "Mark", surname: "Snow", age: 33)
        log.error?.write(msg: "Event message", object: object, extra: ["extra1": "val"], tags: ["tag1": "val1"])
        
        let readJSON = try JSONSerialization.jsonObject(with: Data(contentsOf: fileURL), options: .fragmentsAllowed) as? [String: Any]
        let readObj = try JSONDecoder().decode(UserTest.self, from: (readJSON!["object"] as! String).data(using: .utf8)!)
        
        // Validate root nodes
        XCTAssertEqual(readJSON?["message"] as? String, "Event message")
        XCTAssertEqual(readJSON?["level"] as? String, "3")
        
        // Validate read object passed
        XCTAssertEqual(readObj.name, "Mark")
        XCTAssertEqual(readObj.surname, "Snow")

        // Validate timestamp
        let date: String? = readJSON?.valueAtKeyPath("timestamp")
        XCTAssertNotNil(date)
        XCTAssertNotNil(ISO8601DateFormatter().date(from: date!))
        
        // Validate extra
        let localExtraValue: String? = readJSON?.valueAtKeyPath("extra.extra1")
        XCTAssertEqual(localExtraValue, "val")
        
        let globalExtraValue: String? = readJSON?.valueAtKeyPath("extra.globalExtra")
        XCTAssertEqual(globalExtraValue, "valueExtra")
        
        // Validate tags
        let localTagsValue: String? = readJSON?.valueAtKeyPath("tags.tag1")
        XCTAssertEqual(localTagsValue, "val1")
        
        let globalTagsValue: String? = readJSON?.valueAtKeyPath("tags.globalTag")
        XCTAssertEqual(globalTagsValue, "valueTag")
    }
    
    #if os(iOS) || os(tvOS) || os(watchOS)
    /// This test the `JSONFormatter` encoding an `UIImage` and checking the result along with the metadata associated.
    func test_jsonFormatterWithBase64ImageEncoded() throws {
        let fileURL = URL.temporaryFileURL()

        let jsonFormatter = JSONFormatter.standard()
        jsonFormatter.fields.append(.extra(keys: nil))
        jsonFormatter.encodeDataAsBase64 = true
        let fileTransport = try FileTransport(fileURL: fileURL, {
            $0.formatters = [jsonFormatter]
        })
        
        let log = Log {
            $0.level = .trace
            $0.transports = [fileTransport]
        }
        
        let size = CGSize(width: 100, height: 50)
        let image = UIImage.imageWithSize(size: size, color: .red)
        
        log.error?.write(msg: "Some image here", object: image, extra: ["key1": "val1"], tags: ["mytag": "myvalue"])
        
        let readJSON = try JSONSerialization.jsonObject(with: Data(contentsOf: fileURL), options: .fragmentsAllowed) as? [String: Any?]
        
        // Validate the message
        XCTAssertEqual(readJSON?["message"] as? String, "Some image here")
        
        // Validate metadata
        let className: String? = readJSON?.valueAtKeyPath("objectMetadata.class")
        XCTAssertEqual(className, "UIImage")
        
        let imageWidth: String? = readJSON?.valueAtKeyPath("objectMetadata.origin_width")
        let imageHeight: String? = readJSON?.valueAtKeyPath("objectMetadata.origin_height")
        XCTAssertEqual(imageWidth, "\(size.width)")
        XCTAssertEqual(imageHeight, "\(size.height)")
    }
    #endif

    func test_defaultFieldsBasedFormatterWithCustomFields() throws {
        let fileURL = URL.temporaryFileURL()

        GliderSDK.shared.scope.extra = [:]
        GliderSDK.shared.scope.tags = [:]

        let formatter = FieldsFormatter(fields: [
            .message(),
            .delimiter(style: .spacedPipe),
            .tags(keys: nil, {
                $0.format = .queryString
            }),
            .delimiter(style: .spacedPipe),
            .extra(keys: nil, {
                $0.format = .queryString
            })
        ])
        
        let fileTransport = try FileTransport(fileURL: fileURL, {
            $0.formatters = [formatter]
        })
        
        let log = Log {
            $0.level = .trace
            $0.transports = [fileTransport]
        }
        
        for i in 0..<100 {
            log.error?.write(msg: "Event message \(i)", extra: ["e1": "\(i)"], tags: ["t1": "v1"])
        }
        
        let writtenLogLines = try! String(contentsOfFile: fileURL.path).components(separatedBy: "\r\n").filter({
            $0.isEmpty == false
        })
        
        print("File \(fileURL.path)")
        
        for i in 0..<writtenLogLines.count {
            let line = writtenLogLines[i]
            print(line)
            
            let components = line.components(separatedBy: " | ")
            XCTAssertEqual(components[0], "Event message \(i)")
            XCTAssertEqual(components[1], "tags={t1=v1}")
            XCTAssertEqual(components[2], "extra={e1=\(i)}")
        }
    }
    
    /// Test the default human readable format using `FileTransport` transport layer.
    func test_defaultFieldsBasedFormatter() throws {
        let fileURL = URL.temporaryFileURL()

        let fileTransport = try FileTransport(fileURL: fileURL, {
            $0.formatters = [FieldsFormatter.standard()]
        })
        
        let log = Log {
            $0.level = .trace
            $0.transports = [fileTransport]
        }
        
        for i in 0..<100 {
            log.error?.write(msg: "Event message \(i)")
        }
        
        let writtenLogLines = try! String(contentsOfFile: fileURL.path).components(separatedBy: "\r\n").filter({
            $0.isEmpty == false
        })
        
        for i in 0..<writtenLogLines.count {
            XCTAssertTrue(writtenLogLines[i].contains("| ERRR Event message \(i)"))
        }
    }
    
    /// The following test check if structures like extra, tags and userData are correctly encoded
    /// using `queryString` option.
    func test_fieldBasedFormatterWithQueryStringEncodedStructures() throws {
        let fileURL = URL.temporaryFileURL()

        let fieldFormatter = FieldsFormatter(fields: [
            .message(),
            .delimiter(style: .spacedPipe),
            .userData(keys: nil, {
                $0.format = .queryString
            }),
            .delimiter(style: .spacedPipe),
            .extra(keys: nil, {
                $0.format = .queryString
            }),
            .delimiter(style: .spacedPipe),
            .tags(keys: nil, {
                $0.format = .queryString
            })
        ])

        let fileTransport = try FileTransport(fileURL: fileURL, {
            $0.formatters = [fieldFormatter]
        })
        
        let log = Log {
            $0.level = .trace
            $0.transports = [fileTransport]
        }
                
        log.info?.write({
            $0.message = "test message one"
            $0.extra = ["key1": "val1","key2": "val2", "key3": "val3"]
            $0.tags = ["tag1":"v1"]
            $0.scope.user = User(userId: "id", data: ["ukey":"val"])
        })
        
        let writtenLine = try! String(contentsOfFile: fileURL.path).components(separatedBy: "\r\n").first!
        let expectedLine = "test message one | user data={ukey=val} | extra={key1=val1&key2=val2&key3=val3} | tags={tag1=v1}"
        XCTAssertEqual(writtenLine, expectedLine)
    }
    
    /// The following test validate how the `FieldsFormatter` works.
    func test_fieldsBasedFormatter() throws {
        let fileURL = URL.temporaryFileURL()

        GliderSDK.shared.scope.tags = ["tag0": "valtag0"]
        GliderSDK.shared.scope.user = User(userId: "1234bqbdki9344kd", email: "user@user.com", username: "username", ipAddress: "192.168.0.1", data: ["ukey": "val"])
        
        // Create a field formatter
        let fieldFormatter = FieldsFormatter(fields: [
            .level(style: .short, {
                $0.padding = .right(columns: 10)
            }),
            .delimiter(style: .custom(": ")),
            .message(),
            .delimiter(style: .space),
            .extra(keys: ["key1","key2"], {
                $0.format = .queryString
            }),
            .delimiter(style: .space),
            .tags(keys: ["tag0","tag1","tag3"], {
                $0.format = .queryString
            }),
            .delimiter(style: .space),
            .userData(keys: ["ukey"], {
                $0.format = .queryString
            }),
            .delimiter(style: .space),
            .userId({
                $0.padding = .left(columns: 15)
                $0.truncate = .middle(length: 5)
            }),
            .delimiter(style: .space),
            .username()
        ])
        

        let fileTransport = try FileTransport(fileURL: fileURL, {
            $0.formatters =  [fieldFormatter]
        })
        
        let log = Log {
            $0.level = .trace
            $0.transports = [fileTransport]
        }
                
        log.info?.write({
            $0.message = "test message one"
            $0.extra = ["key1": "val1","key2": "val2", "key3": "val3"]
        })
        
        log.error?.write({
            $0.message = "another message"
            $0.tags = ["tag1": "valtag1", "tag2": "valtag2"]
        })
        
        let writtenLogLines = try! String(contentsOfFile: fileURL.path).components(separatedBy: "\r\n").filter({
            $0.isEmpty == false
        })
        
        let expectedLines = [
            "      INFO: test message one extra={key1=val1&key2=val2} tags={tag0=valtag0} user data={ukey=val} 12…kd           username",
            "      ERRR: another message  tags={tag0=valtag0&tag1=valtag1} user data={ukey=val} 12…kd           username"
        ]
        
        for i in 0..<writtenLogLines.count {
            XCTAssertEqual(writtenLogLines[i], expectedLines[i])
        }
        
    }
    
    // MARK: - Private Functions
    
    private func createTestWithExtraFormattingOfType(_ type: FieldsFormatter.StructureFormatStyle, onReceiveEvent: @escaping ((Event, String) -> Void)) {
        let fieldFormatter = FieldsFormatter(fields: [
                .timestamp(style: .iso8601),
                .message(),
                .literal(" "),
                .extra(keys: ["key1", "key2", "key3"], {
                    $0.format = type
                })
        ])
        
        let log = Log {
            $0.level = .trace
            $0.transports = [
                TestTransport(formatters: [fieldFormatter], onReceiveEvent: { event, message in
                    print(message)
                    onReceiveEvent(event, message)
                })
            ]
        }
        
        log.info?.write({
            $0.message = "Hello welcome here!"
            $0.extra = [
                "key1": "a_simple_value",
                "key2": "another_value"
            ]
        })
    }
    
}

fileprivate struct UserTest: SerializableObject, Codable {
    public var name: String
    public var surname: String?
    public var age: Int
    public var createdAt: Date = .init()
    public var role: String?
}

#if os(iOS) || os(tvOS) || os(watchOS)

fileprivate extension UIImage {
    
     static func imageWithSize(size : CGSize, color : UIColor = UIColor.white) -> UIImage? {
         var image:UIImage? = nil
         UIGraphicsBeginImageContext(size)
         if let context = UIGraphicsGetCurrentContext() {
               context.setFillColor(color.cgColor)
               context.addRect(CGRect(origin: CGPoint.zero, size: size));
               context.drawPath(using: .fill)
               image = UIGraphicsGetImageFromCurrentImageContext();
        }
        UIGraphicsEndImageContext()
        return image
    }
    
    
}

#endif
