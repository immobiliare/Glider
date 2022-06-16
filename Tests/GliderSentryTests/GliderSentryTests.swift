import XCTest
@testable import GliderSentry
import Glider

final class GliderSentryTests: XCTestCase {
   
    
    func testSentryTransport() async throws {
        
        let exp = expectation(description: "test")
        
        let ff = FieldsFormatter(fields: [
            .message()
        ])
        
        let sentry = SentryTransport {
            $0.sdkConfiguration = .init()
            $0.sdkConfiguration?.dsn = "https://9c3d979175e048518569a93eda03ab58@sentry.pepita.io/38"
            $0.sdkConfiguration?.debug = true
            $0.formatters = [ff]
        }
        
        let log = Log {
            $0.level = .debug
            $0.transports = [sentry]
        }
        
        log.info?.write("test message")
        
        wait(for: [exp], timeout: 60)
        
    }
    
}
