import XCTest
@testable import Glider
import Sentry

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
            
            log[writeLevel]?.write {
                if shouldPass == false {
                    XCTFail("Event building should never happend")
                } else {
                    hasPassed = true
                }
                return .init("dummy event")
            }
            
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
        XCTAssertNotNil(sentEvent?.scope.runtimeContext, "Runtime attributes should be not empty")
        XCTAssertEqual(sentEvent?.scope.runtimeContext?.fileName, (#file as NSString).lastPathComponent, "Incorrect runtime context attributes")
        
        let currentThreadId = ProcessIdentification.threadID()
        XCTAssertEqual(sentEvent?.scope.runtimeContext?.threadID, currentThreadId, "Event should include correct thread identifier")
    }
    
}
