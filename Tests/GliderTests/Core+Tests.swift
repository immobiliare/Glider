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

final class CoreTests: XCTestCase {
    
    func test_multipleThreads() throws {
        let exp1 = expectation(description: "Finish 1")
        let exp2 = expectation(description: "Finish 2")
        let exp3 = expectation(description: "Finish 3")

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 3
        
        let messagesCount = 100
        var receivedMessagesCount = 0
        
        let log = Log {
            $0.level = .trace
            $0.transports = [
                ConsoleTransport(),
                TestTransport(onReceiveEvent: { _ in
                    receivedMessagesCount += 1
                })
            ]
        }
                
        let op1 = BlockOperation(block: {
            for i in 0..<messagesCount {
                let level = Level.allCases.randomElement() ?? .debug
                log[level]?.write(msg: "Msg from thread 1: \(i)")
            }
            
            exp1.fulfill()
        })

        let op2 = BlockOperation(block: {
            for i in 0..<messagesCount {
                let level = Level.allCases.randomElement() ?? .debug
                log[level]?.write(msg: "Msg from thread 2: \(i)")
            }
            
            exp2.fulfill()
        })

        let op3 = BlockOperation(block: {
            for i in 0..<messagesCount {
                let level = Level.allCases.randomElement() ?? .debug
                log[level]?.write(msg: "Msg from thread 3: \(i)")
            }
            
            exp3.fulfill()
        })
        
        queue.addOperation(op1)
        queue.addOperation(op2)
        queue.addOperation(op3)
        
        wait(for: [exp1, exp2, exp3], timeout: 10)
        queue.waitUntilAllOperationsAreFinished()
                
        XCTAssertEqual(receivedMessagesCount, messagesCount * 3)
    }
    
    /// Test the log levels hierarchy of severities.
    func test_logLevels() throws {
        XCTAssertTrue(Level.emergency.isMoreSevere(than: .alert))
        XCTAssertTrue(Level.alert.isMoreSevere(than: .critical))
        XCTAssertTrue(Level.critical.isMoreSevere(than: .error))
        XCTAssertTrue(Level.error.isMoreSevere(than: .warning))
        XCTAssertTrue(Level.warning.isMoreSevere(than: .notice))
        XCTAssertTrue(Level.notice.isMoreSevere(than: .info))
        XCTAssertTrue(Level.info.isMoreSevere(than: .debug))
    }
    
    /// This test validate the existence of a channel associated to each log level
    /// below (including) a set maximum severity level. It also check if any more severe
    /// level is nil because disabled.
    func test_logChannels() throws {
        
        func testLogChannelsForLevel(_ maxLevel: Level) {
            let log = Log {
                $0.level = maxLevel
            }
            
            
            for rawLevel in 0..<log.channels.count {
                let level = Level(rawValue: rawLevel)!
                if level > maxLevel {
                    XCTAssertNil(log.channels[rawLevel], "Channel should be nil because log level is more severe than \(maxLevel)")
                } else {
                    XCTAssertNotNil(log.channels[rawLevel], "Channel should be available for log level \(level)")
                }
            }
        }
        
        testLogChannelsForLevel(.warning)
        testLogChannelsForLevel(.debug)
        testLogChannelsForLevel(.critical)
    }
    
    /// The following test check if a channel can ignore correctly the
    /// building of an event when the parent log is disabled or its level
    /// is below the parent log level.
    /// This avoid unnecessary cpu operations reducing the footprint of the
    /// logging operation itself.
    func test_logChannelsGatekeeping() throws {
        
        func testGatekeeper(logLevel: Level, writeLevel: Level, shouldPass: Bool)  {
            var hasPassed = false
            let log = Log {
                $0.level = logLevel
            }
            
            log[writeLevel]?.write({
                if shouldPass == false {
                    XCTFail("Event building should never happend")
                } else {
                    hasPassed = true
                }
                $0.message = "dummy event"
            })
            
            if shouldPass && hasPassed == false {
                XCTFail("Event building should be called")
            }
        }
        
        testGatekeeper(logLevel: .debug, writeLevel: .debug, shouldPass: true)
        testGatekeeper(logLevel: .error, writeLevel: .debug, shouldPass: false)
    }
    
    /// The following test check if the runtime context attributes are attached
    /// correctly to a new created event.
    func test_eventRuntimeContext() throws {
        GliderSDK.shared.contextsCaptureOptions = .all
        
        let log = Log {
            $0.level = .debug
        }
        
        let sentEvent = log.debug?.write {
            $0.message = "This is a dummy event"
        }
        
        XCTAssertNotNil(sentEvent, "Event should be dispatched correctly")
        XCTAssertNotNil(sentEvent?.scope.context, "Runtime attributes should be not empty")
        XCTAssertEqual(sentEvent?.scope.fileName, (#file as NSString).lastPathComponent, "Incorrect runtime context attributes")
        
        let currentThreadId = ProcessIdentification.shared.threadID
        XCTAssertEqual(sentEvent?.scope.threadID, currentThreadId, "Event should include correct thread identifier")
    }
    
    
    /// The following test check if the message, both as a literal string or computed string
    /// is dispatched correctly to the underlying transporters.
    func test_writeLiteralsAndComputedMessages() throws {
        let log = Log {
            $0.level = .debug
        }
        
        let refDate = Date(timeIntervalSince1970: 0)
        
        let event1 = log.debug?.write(msg: "Hello")
        let event2 = log.debug?.write(msg: {
            let date = ISO8601DateFormatter().string(from: refDate)
            return "Hello, it's \(date)"
        }())
        
        XCTAssertEqual(event1?.message.description, "Hello", "Literal message is not filled correctly")
        XCTAssertEqual(event2?.message.description, "Hello, it's 1970-01-01T00:00:00Z", "Computed message literal is not correct")
    }
    
    /// The following test check if event filters are working correctly to ignore
    /// or pass events to the underlying transports.
    /// It also check if event level is correct and all messages are received in order when sync mode is active.
    func test_eventFilters() throws {
        // Create a list of events with an extra index information; each event
        // has a progressive number from 0 to 100.
        var events = (0..<100).map {
            Event(message: "Message #\($0)", extra: ["idx": $0])
        }

        // We'll add two filters:
        // - filter only odd values
        // - filter only values below 50 excluded
        // - moreover the first log event should not be read because has a lower level than expected
        let oddFilter = CallbackFilter {
            ($0.extra?["idx"] as! Int).isMultiple(of: 2)
        }
        
        let maxValueFilter = CallbackFilter {
            ($0.extra?["idx"] as! Int) < 50
        }
        
        // We'll check if transport receive correct events filtered.
        var countReceivedEvents = 0
        var prevReceivedValue: Int?
        let finalTransport = TestTransport { eventReceived in
            let valueAssociated = eventReceived.extra?["idx"] as! Int
            XCTAssertTrue(valueAssociated.isMultiple(of: 2), "Odd filter does not work as expected")
            XCTAssertTrue(valueAssociated < 50, "Max value filter does not work as expected")
            XCTAssertEqual("Message #\(valueAssociated)", eventReceived.message.description, "Message received is wrong")
            XCTAssertEqual(eventReceived.level, .info, "Expected value is not received")
            
            if let prevReceivedValue = prevReceivedValue {
                XCTAssertTrue(prevReceivedValue < valueAssociated, "Events are not received in strict order")
            }
            
            countReceivedEvents += 1
            prevReceivedValue = valueAssociated
        }
        
        let log = Log {
            $0.level = .info
            $0.isSynchronous = true
            $0.filters = [
                oddFilter,
                maxValueFilter
            ]
            $0.transports = [
                finalTransport
            ]
        }
        
        for i in 0..<events.count {
            let level: Level = (i == 0 ? .debug : .info)
            log[level]?.write(event: &events[i])
        }
        
        XCTAssertTrue(countReceivedEvents == 24, "Filter does not work as expected, total filtered values are wrong")
    }

    /// The following test check if subsystem and category are sent correctly.
    func test_subsystemAndCategory() throws {
        
        let log = Log {
            $0.subsystem = LogSubsystem.coreApplication
            $0.category = LogCategory.network
            $0.level = .debug
        }
        
        let event1 = log.debug?.write(msg: "Literal msg")
        let event2 = log.debug?.write({
            $0.message = "Computed msg with event"
        })
        let event3 = log.debug?.write(msg: {
            "Computed msg with string"
        }())
        
        [event1, event2, event3].forEach { event in
            guard let event = event else {
                XCTFail("Event should be sent correctly")
                return
            }
            
            XCTAssertEqual(event.subsystem?.description, LogSubsystem.coreApplication.rawValue)
            XCTAssertEqual(event.category?.description, LogCategory.network.rawValue)
        }
    }
    
    /// The following test check if captured context attributes are correctly managed based upon active options.
    func test_contextCapturingOptions() throws {
        let log = Log {
            $0.level = .debug
        }

        // Test if context is not captured when turned off the option
        GliderSDK.shared.contextsCaptureOptions = .none
        let noContextEvent = log.debug?.write(msg: "")
        XCTAssertNil(noContextEvent?.scope.context, "Context should be not captured in this mode")
        
        // Test if context is captured correctly when turned on
        GliderSDK.shared.contextsCaptureOptions = [.os]
        let onlyOSContextEvent = log.debug?.write(msg: "")
        XCTAssertNotNil(onlyOSContextEvent?.scope.context?.os, "OS related context attributes must be present")
        XCTAssertNil(onlyOSContextEvent?.scope.context?.device, "Device related context attributes must not be present")
        
        // Test if context is captured correctly when all flags are turned on
        GliderSDK.shared.contextsCaptureOptions = .all
        let allContextsCapturedEvent = log.debug?.write(msg: "")
        XCTAssertNotNil(allContextsCapturedEvent?.scope.context?.os, "OS related context attributes must be present")
        XCTAssertNotNil(allContextsCapturedEvent?.scope.context?.device, "Device related context attributes must be present")
    }
    
    /// The following test check if tags and extra dictionaries are merged correctly
    /// between the event's specific values and the scope's value.
    func test_eventExtraAndTagsMergeWithScope() throws {
        let log = Log {
            $0.level = .debug
        }
        
        // Setup some global tags and extra values
        GliderSDK.shared.scope.tags = [
            "tag1": "scope_value",
            "tag2": "scope_value"
        ]
        
        GliderSDK.shared.scope.extra = [
            "extra1": "scope_value",
            "extra2": "scope_value",
            "extra4": "scope_value"
        ]
        
        let eventExtra: Metadata = [
            "extra1": "event_value",
            "extra3": "event_value"
        ]
        
        let tagsExtra: Tags = [
            "tag1": "event_value",
            "tag3": "event_value"
        ]
        
        // Attach to event custom extra and tags values, some of them will override existing
        // keys inside the scope's extra and tags.
        var event = Event(message: "test message", extra: eventExtra, tags: tagsExtra)
        let proposedEvent = log.debug?.write(event: &event)
        let proposedEvent2 = log.debug?.write({
            $0.message = "test message"
            $0.tags = tagsExtra
            $0.extra = eventExtra
        })
        
        validateEvent(proposedEvent)
        validateEvent(proposedEvent2!)

        func validateEvent(_ sentEvent: Event?) {
            guard let sentEvent = sentEvent else {
                XCTFail()
                return
            }
            
            // Check if the resulting event combines two dictionary values.
            XCTAssertEqual(sentEvent.allTags?.keys.count, 3)
            XCTAssertEqual(sentEvent.allTags?["tag1"], "event_value")
            XCTAssertEqual(sentEvent.allTags?["tag2"], "scope_value")
            XCTAssertEqual(sentEvent.allTags?["tag3"], "event_value")
            
            XCTAssertEqual(sentEvent.allExtra?.keys.count, 4)
            XCTAssertEqual(sentEvent.allExtra?["extra1"] as? String, "event_value")
            XCTAssertEqual(sentEvent.allExtra?["extra2"] as? String, "scope_value")
            XCTAssertEqual(sentEvent.allExtra?["extra4"] as? String, "scope_value")
        }
        
    }
    
    /// The following tests check if automatic encoding of `UIImage` works properly.
    func test_eventObjectSerializationWithUIImage() async throws {
        let imageData = try! Data(contentsOf: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fb/Wikisource-logo.png/360px-Wikisource-logo.png")!)
        let image = UIImage(data: imageData)
        
        let transport = TestTransport {
            guard let _ = UIImage(data: $0.serializedObjectData!) else {
                XCTFail("Failed to decoded the image")
                return
            }
            
            XCTAssertNotNil($0.serializedObjectMetadata)
        }
        
        let log = Log {
            $0.level = .debug
            $0.transports = [ transport ]
        }
        
        log.info?.write({
            $0.object = image
        })
        
    }
    
    /// The following test check if custom serialization for `SerializableObject` objects works properly.
    func test_eventObjectSerializationWithCustomSerializeFunction() async throws {
        
        struct Company: SerializableObject {
            var name: String
            var foundedDate: Date?
            var homepage: URL
            var founders: [String]
            
            func serializeMetadata() -> Metadata? {
                [
                    "class": "company_class"
                ]
            }
            
            func serialize(with strategies: SerializationStrategies) -> Data? {
                "name:\(name)\nfoundedDate:\(foundedDate?.timeIntervalSince1970 ?? 0)\nhomepage:\(homepage.absoluteString)\nfounders=\(founders.joined(separator: ","))".data(using: .utf8)!
            }
            
        }
        
        let company = Company(name: "ExSpace", foundedDate: Date(), homepage: URL(string: "http://www.exspace.com")!, founders: ["Mark","Jane"])

        let transport = TestTransport {
            XCTAssertNotNil($0.serializedObjectData, "Failed to transport serialized data")
            
            // Validate metadata
            XCTAssertEqual($0.serializedObjectMetadata?["class"] as? String, "company_class")
         
            // Validate data
            guard let rawData = $0.serializedObjectData else {
                XCTFail("Failed to read the serialized object data")
                return
            }
            
            let rawString = String(data: rawData, encoding: .utf8)!
            let expectedString = "name:\(company.name)\nfoundedDate:\(company.foundedDate?.timeIntervalSince1970 ?? 0)\nhomepage:\(company.homepage.absoluteString)\nfounders=\(company.founders.joined(separator: ","))"
            
            XCTAssertEqual(rawString, expectedString, "Failed to check correctness of the raw data for serialized object")
        }
        
        let log = Log {
            $0.level = .debug
            $0.transports = [ transport ]
        }
                
        log.info?.write({
            $0.object = company
        })
        
    }
    
    func test_eventObjectSerialization() async throws {
        
        struct People: SerializableObject, Codable {
            func serializeMetadata() -> Metadata? {
                [
                    "class": "People",
                    "interesting_key": "any_value"
                ]
            }
            
            var name: String
            var age: Int
            var avatar: URL?
        }
        
        let transport = TestTransport {
            XCTAssertNotNil($0.serializedObjectData, "Failed to transport serialized data")
            
            // Validate metadata
            XCTAssertEqual($0.serializedObjectMetadata?["class"] as? String, "People")
            XCTAssertEqual($0.serializedObjectMetadata?["interesting_key"] as? String, "any_value")
            
            // Validate serialized data
            do {
                guard let data = $0.serializedObjectData else {
                    XCTFail("Failed to transport serialized data of the object")
                    return
                }
                
                _ = try JSONDecoder().decode(People.self, from: data)
            } catch {
                XCTFail("Failed to decoded transported serialized data: \(error.localizedDescription)")
            }
        }
        
        let log = Log {
            $0.level = .debug
            $0.transports = [ transport ]
        }
        
        let people = People(name: "Mark", age: 11, avatar: URL(string: "http://mywebsite.com/users/avatars/user12.jpg"))
        
        log.info?.write({
            $0.object = people
        })
        
    }
    
}


// MARK: - Helper Structures

fileprivate enum LogSubsystem: String, LoggerIdentifiable {
    case coreApplication = "com.myapp.core"
    case externalFramework = "com.myapp.externalframework"
    
    var id: String {
        rawValue
    }
}

fileprivate enum LogCategory: String, LoggerIdentifiable {
    case network = "com.myapp.networking"
    case storage = "com.myapp.storage"
    
    var id: String {
        rawValue
    }
}

fileprivate class CallbackFilter: TransportFilter {
    typealias Callback = ((Event) -> Bool)
    
    private var callback: Callback
    
    init(_ callback: @escaping Callback) {
        self.callback = callback
    }
    
    func shouldAccept(_ event: Event) -> Bool {
        callback(event)
    }
    
}

public class TestTransport: Transport {
    typealias OnReceiveEvent = ((Event) -> Void)

    private var onReceiveEvent: OnReceiveEvent?
    
    /// Transport is enabled.
    public var isEnabled: Bool = true
    
    init(onReceiveEvent: @escaping OnReceiveEvent) {
        self.onReceiveEvent = onReceiveEvent
    }
    
    public func record(event: Event) -> Bool {
        onReceiveEvent?(event)
        return true
    }
    
    public var queue: DispatchQueue? = DispatchQueue(label: "com.test.transport", qos: .background)
    
}
