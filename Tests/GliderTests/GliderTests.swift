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
    
    func test_logChannelsSending() throws {
        let log = Log {
            $0.level = .error
        }
        
        log.debug?.write {
            var event = Event("Ciao")
            return event
        }
    }
    
}
