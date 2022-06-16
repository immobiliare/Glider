import XCTest
@testable import Glider
@testable import GliderSentry

final class GliderSentryTests: XCTestCase {
   
    
    func testSentryTransport() async throws {
        
        let exp = expectation(description: "test")
        
        let ff = FieldsFormatter(fields: [
            .message()
        ])
        
        let sentry = GliderSentryTransport {
            $0.sdkConfiguration = .init()
            $0.sdkConfiguration?.dsn = "<REPLACE WITH DSN>"
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
