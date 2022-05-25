//
//  File.swift
//  
//
//  Created by Daniele Margutti on 24/05/22.
//

import Foundation

import XCTest
@testable import Glider

final class FormattersTest: XCTestCase {
    
    /// This tests check the `JSONFormatter`.
    func test_jsonFormatter() async throws {
        let fileURL = URL.newLogFileURL(removeContents: true)

        let jsonFormatter = JSONFormatter.default()
        let fileTransport = FileTransport(fileURL: fileURL, formatters: [jsonFormatter])!

        let log = Log {
            $0.level = .debug
            $0.transports = [fileTransport]
        }
        
        GliderSDK.shared.scope.tags = ["globalTag": "valueTag"]
        GliderSDK.shared.scope.extra = ["globalExtra": "valueExtra"]

        let object = UserTest(name: "Mark", surname: "Snow", age: 33)
        log.error?.write("Event message", object: object, extra: ["extra1": "val"], tags: ["tag1": "val1"])
        
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
    
    /// This test the `JSONFormatter` encoding an `UIImage` and checking the result along with the metadata associated.
    func test_jsonFormatterWithBase64ImageEncoded() async throws {
        let fileURL = URL.newLogFileURL(removeContents: true)

        let jsonFormatter = JSONFormatter.default()
        jsonFormatter.fields.append(.extra(keys: nil))
        jsonFormatter.encodeDataAsBase64 = true
        let fileTransport = FileTransport(fileURL: fileURL, formatters: [jsonFormatter])!

        let log = Log {
            $0.level = .debug
            $0.transports = [fileTransport]
        }
        
        let size = CGSize(width: 100, height: 50)
        let image = UIImage.imageWithSize(size: size, color: .red)
        
        log.error?.write("Some image here", object: image, extra: ["key1": "val1"], tags: ["mytag": "myvalue"])
        
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

    func test_defaultFieldsBasedFormatterWithCustomFields() async throws {
        let fileURL = URL.newLogFileURL(removeContents: true)

        let formatter = FieldsFormatter(fields: [
            .message(),
            .delimiter(style: .spacedPipe),
            .tags(keys: nil),
            .delimiter(style: .spacedPipe),
            .extra(keys: nil)
        ])
        
        let fileTransport = FileTransport(fileURL: fileURL, formatters: [formatter])!
        let log = Log {
            $0.level = .debug
            $0.transports = [fileTransport]
        }
        
        for i in 0..<100 {
            log.error?.write("Event message \(i)", extra: ["e1": "\(i)"], tags: ["t1": "v1"])
        }
        
        let writtenLogLines = try! String(contentsOfFile: fileURL.path).components(separatedBy: "\n").filter({
            $0.isEmpty == false
        })
        
        for i in 0..<writtenLogLines.count {
            let line = writtenLogLines[i]
            let components = line.components(separatedBy: " | ")
            XCTAssertEqual(components[0], "Event message \(i)")
            XCTAssertEqual(components[1], "tags={{\"t1\":\"v1\"}}")
            XCTAssertEqual(components[2], "extra={{\"e1\":\"\(i)\"}}")
        }
    }
    
    /// Test the default human readable format using `FileTransport` transport layer.
    func test_defaultFieldsBasedFormatter() async throws {
        let fileURL = URL.newLogFileURL(removeContents: true)
        
        let fileTransport = FileTransport(fileURL: fileURL, formatters: [FieldsFormatter.default()])!
        let log = Log {
            $0.level = .debug
            $0.transports = [fileTransport]
        }
        
        for i in 0..<100 {
            log.error?.write("Event message \(i)")
        }
        
        let writtenLogLines = try! String(contentsOfFile: fileURL.path).components(separatedBy: "\n").filter({
            $0.isEmpty == false
        })
        
        for i in 0..<writtenLogLines.count {
            XCTAssertTrue(writtenLogLines[i].contains("| ERRR Event message \(i)"))
        }
    }
    
    /// The following test validate how the `FieldsFormatter` works.
    func test_fieldsBasedFormatter() async throws {
        let fileURL = URL.newLogFileURL(removeContents: true)
        
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
            .extra(keys: ["key1","key2"]),
            .delimiter(style: .space),
            .tags(keys: ["tag0","tag1","tag3"]),
            .delimiter(style: .space),
            .userData(keys: ["ukey"]),
            .delimiter(style: .space),
            .userId({
                $0.padding = .left(columns: 15)
                $0.truncate = .middle(length: 5)
            }),
            .delimiter(style: .space),
            .username()
        ])

        let fileTransport = FileTransport(fileURL: fileURL, formatters: [fieldFormatter])!
        
        let log = Log {
            $0.level = .debug
            $0.transports = [fileTransport]
        }
                
        log.info?.write(event: {
            $0.message = "test message one"
            $0.extra = ["key1": "val1","key2": "val2", "key3": "val3"]
        })
        
        log.error?.write(event: {
            $0.message = "another message"
            $0.tags = ["tag1": "valtag1", "tag2": "valtag2"]
        })
        
        let writtenLogLines = try! String(contentsOfFile: fileURL.path).components(separatedBy: "\n").filter({
            $0.isEmpty == false
        })
        
        let expectedLines = [
            "      INFO: test message one extra={{\"key1\":\"val1\",\"key2\":\"val2\"}} tags={{\"tag0\":\"valtag0\"}} userData={{\"ukey\":\"val\"}} 12…kd           username",
            "      ERRR: another message  tags={{\"tag0\":\"valtag0\",\"tag1\":\"valtag1\"}} userData={{\"ukey\":\"val\"}} 12…kd           username"
        ]
        
        for i in 0..<writtenLogLines.count {
            XCTAssertEqual(writtenLogLines[i], expectedLines[i])
        }
        
    }
    
}

fileprivate struct UserTest: SerializableObject, Codable {
    public var name: String
    public var surname: String?
    public var age: Int
    public var createdAt: Date = .init()
    public var role: String?
}

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

extension Dictionary {
    
    public func valueAtKeyPath<T>(_ keyPath: String) -> T? {
        var keys = keyPath.components(separatedBy: ".")
        guard let first = keys.first as? Key else {
            debugPrint("Unable to use string as key on type: \(Key.self)")
            return nil
        }
        
        guard let value = self[first] else {
            return nil
        }
        
        keys.remove(at: 0)
        if !keys.isEmpty, let subDict = value as? [String : Any?] {
            let rejoined = keys.joined(separator: ".")
            
            return subDict.valueAtKeyPath(rejoined)
        }
        return value as? T
    }
    
}
