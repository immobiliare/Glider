import XCTest
@testable import Glider

final class GliderTests: XCTestCase {
    
    /// Test the log levels hierarchy of severities.
    func test_logLevelTests() throws {
        XCTAssertTrue(Log.Level.emergency.isMoreSevere(than: .alert))
        XCTAssertTrue(Log.Level.alert.isMoreSevere(than: .critical))
        XCTAssertTrue(Log.Level.critical.isMoreSevere(than: .error))
        XCTAssertTrue(Log.Level.error.isMoreSevere(than: .warning))
        XCTAssertTrue(Log.Level.warning.isMoreSevere(than: .notice))
        XCTAssertTrue(Log.Level.notice.isMoreSevere(than: .info))
        XCTAssertTrue(Log.Level.info.isMoreSevere(than: .debug))
    }
    
}
