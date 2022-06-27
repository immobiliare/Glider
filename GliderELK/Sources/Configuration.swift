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
import Glider
import NIO
import NIOConcurrencyHelpers
import Logging
import AsyncHTTPClient

extension GliderELKTransport {
    
    public struct Configuration {
        
        /// The host where a Logstash instance is running
        public var hostname: String
 
        /// The port of the host where a Logstash instance is running
        public var port: Int
        
        /// Specifies if the HTTP connection to Logstash should be encrypted via TLS (so HTTPS instead of HTTP)
        public var useHTTPS = false
        
        /// The `EventLoopGroup` which is used to create the `HTTPClient`
        public var eventLoopGroup: EventLoopGroup
        
        /// Represents a certain amount of time which serves as a delay between the triggering of the uploading to Logstash
        public var uploadInterval: TimeAmount
        
        /// Specifies how large the log storage `ByteBuffer` must be at least
        public var logStorageSize: Int = 524_288
        
        /// Specifies how large the log storage `ByteBuffer` with all the current uploading buffers can be at the most
        public var maximumTotalLogStorageSize: Int = 4_194_304
        
        /// Used to log background activity of the transport and `HTTPClient`.
        /// This logger MUST be created BEFORE the `LoggingSystem` is bootstrapped, else it results in an infinte recusion!
        public var backgroundActivityLogger: Logger
        
        /// The `JSONEncoder` used to encode the event.
        /// By default you should never need to change it.
        public var jsonEncoder: JSONEncoder = {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            encoder.dataEncodingStrategy = .base64
            encoder.nonConformingFloatEncodingStrategy = .convertToString(
                positiveInfinity: "+inf",
                negativeInfinity: "-inf",
                nan: "NaN"
            )
            return encoder
        }()
        
        /// Initialize a new configuration for ELK transport service.
        ///
        /// - Parameters:
        ///   - hostname: hostname.
        ///   - port: port of connection.
        ///   - builder: builder to setup extra settings.
        public init(hostname: String, port: Int, _ builder: ((inout Configuration) -> Void)?) throws {
            self.hostname = hostname
            self.port = port
            let threadsCount = (System.coreCount != 1) ? System.coreCount / 2 : 1
            self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: threadsCount)
            self.uploadInterval = TimeAmount.seconds(3)
            
            self.backgroundActivityLogger = Logger(label: "backgroundActivity-logstashHandler")
            
            builder?(&self)
            
            // Validate data
            
            // If the double minimum log storage size is larger than maximum log storage size throw error
            if maximumTotalLogStorageSize.nextPowerOf2() < (2 * logStorageSize.nextPowerOf2()) {
                throw GliderError(message: "maximumLogStorageSize needs to be at least twice as much (spoken in terms of the power of two) as the passed minimumLogStorageSize.")
            }
            
            // Round up to the power of two since ByteBuffer automatically allocates in these steps
            logStorageSize = logStorageSize.nextPowerOf2()
            maximumTotalLogStorageSize = maximumTotalLogStorageSize.nextPowerOf2()
        }
        
    }
    
}
