import XCTest
@testable import Glider

final class GliderTests: XCTestCase {
    
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
            
            log[writeLevel]?.write(event: {
                if shouldPass == false {
                    XCTFail("Event building should never happend")
                } else {
                    hasPassed = true
                }
                return .init("dummy event")
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
        let log = Log {
            $0.level = .debug
        }
        
        let sentEvent = log.debug?.write {
            Event("This is a dummy event")
        }
        
        XCTAssertNotNil(sentEvent, "Event should be dispatched correctly")
        XCTAssertNotNil(sentEvent?.scope.context, "Runtime attributes should be not empty")
        XCTAssertEqual(sentEvent?.scope.fileName, (#file as NSString).lastPathComponent, "Incorrect runtime context attributes")
        
        let currentThreadId = ProcessIdentification.threadID()
        XCTAssertEqual(sentEvent?.scope.threadID, currentThreadId, "Event should include correct thread identifier")
    }
    
    
    /// The following test check if the message, both as a literal string or computed string
    /// is dispatched correctly to the underlying transporters.
    func test_writeLiteralsAndComputedMessages() throws {
        let log = Log {
            $0.level = .debug
        }
        
        let refDate = Date(timeIntervalSince1970: 0)
        
        let event1 = log.debug?.write(message: "Hello")
        let event2 = log.debug?.write(message: {
            let date = ISO8601DateFormatter().string(from: refDate)
            return "Hello, it's \(date)"
        })
        
        XCTAssertEqual(event1?.message, "Hello", "Literal message is not filled correctly")
        XCTAssertEqual(event2?.message, "Hello, it's 1970-01-01T00:00:00Z", "Computed message literal is not correct")
    }
    
    /// The following test check if event filters are working correctly to ignore
    /// or pass events to the underlying transports.
    /// It also check if event level is correct and all messages are received in order when sync mode is active.
    func test_eventFilters() throws {
        // Create a list of events with an extra index information; each event
        // has a progressive number from 0 to 100.
        var events = (0..<100).map {
            Event("Message #\($0!)", extra: ["idx": $0])
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
            let valueAssociated = eventReceived.extra!["idx"] as! Int
            XCTAssertTrue(valueAssociated.isMultiple(of: 2), "Odd filter does not work as expected")
            XCTAssertTrue(valueAssociated < 50, "Max value filter does not work as expected")
            XCTAssertEqual("Message #\(valueAssociated)", eventReceived.message, "Message received is wrong")
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
        
        let event1 = log.debug?.write(message: "Literal msg")
        let event2 = log.debug?.write(event: {
            Event("Computed msg with event")
        })
        let event3 = log.debug?.write(message: {
            "Computed msg with string"
        })
        
        [event1, event2, event3].forEach { event in
            guard let event = event else {
                XCTFail("Event should be sent correctly")
                return
            }
            
            XCTAssertEqual(event.subsystem?.description, LogSubsystem.coreApplication.rawValue)
            XCTAssertEqual(event.category?.description, LogCategory.network.rawValue)
        }
    }
    
    func test_contextCapturingOptions() throws {
        let log = Log {
            $0.level = .debug
        }

        // Test if context is not captured when turned off the option
        GliderSDK.shared.contextsCaptureOptions = .none
        let noContextEvent = log.debug?.write(message: "")
        XCTAssertNil(noContextEvent?.scope.context, "Context should be not captured in this mode")
        
        // Test if context is captured correctly when turned on
        GliderSDK.shared.contextsCaptureOptions = [.os]
        let onlyOSContextEvent = log.debug?.write(message: "")
        XCTAssertNotNil(onlyOSContextEvent?.scope.context?.os, "OS related context attributes must be present")
        XCTAssertNil(onlyOSContextEvent?.scope.context?.device, "Device related context attributes must not be present")
        
        // Test if context is captured correctly when all flags are turned on
        GliderSDK.shared.contextsCaptureOptions = .all
        let allContextsCapturedEvent = log.debug?.write(message: "")
        XCTAssertNotNil(allContextsCapturedEvent?.scope.context?.os, "OS related context attributes must be present")
        XCTAssertNotNil(allContextsCapturedEvent?.scope.context?.device, "Device related context attributes must be present")
    }
    
}


// MARK: - Helper Structures

fileprivate enum LogSubsystem: String, LogUUID {
    case coreApplication = "com.myapp.core"
    case externalFramework = "com.myapp.externalframework"
    
    var description: String {
        rawValue
    }
}

fileprivate enum LogCategory: String, LogUUID {
    case network = "com.myapp.networking"
    case storage = "com.myapp.storage"
    
    var description: String {
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

fileprivate class TestTransport: Transport {
    typealias OnReceiveEvent = ((Event) -> Void)

    private var onReceiveEvent: OnReceiveEvent?
    
    init(onReceiveEvent: @escaping OnReceiveEvent) {
        self.onReceiveEvent = onReceiveEvent
    }
    
    func record(event: Event) -> Bool {
        onReceiveEvent?(event)
        return true
    }
    
    var queue: DispatchQueue? = DispatchQueue(label: "com.test.transport", qos: .background)
    
}
