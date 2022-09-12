//
//  Glider
//  Fast, Lightweight yet powerful logging system for Swift.
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Authors:
//   - Daniele Margutti <hello@danielemargutti.com>
//
//  Copyright ©2022 Immobiliare.it SpA.
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
        
        // MARK: - Public Properties
        
        /// Is the transport enabled. By default is set to `true`.
        public var isEnabled = true
        
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
        
        /// The `DispatchQueue` to use for the recorder.
        public var queue: DispatchQueue
        
        /// Specifies how large the log storage `ByteBuffer` with all the current uploading buffers can be at the most.
        ///
        /// NOTE:
        /// The `maximumTotalLogStorageSize` MUST be at least twice as large as the logStorageSize
        /// (this is also validated during instanciation of the LogstashLogHandler).
        /// The reason for this are the temporary buffers that are allocated during uploading
        /// of the log data, so that a simultaneous logging call doesn't block
        /// (except for the duration it takes to copy the logs to the temporary buffer which is very fast).
        ///
        /// DISCUSSION
        /// <https://github.com/Apodini/swift-log-elk>
        /// Why at least twice as large? The process of allocating temporary buffers could possibly be repeated,
        /// if the log storage runs full during uploading of "old" log data. A possible scenario is an environment,
        /// where the network conncection to Logstash is really slow and therefore the uploading takes long.
        ///
        /// This process could repeat itself over and over again until the maximumTotalLogStorageSize is reached.
        /// Then, a new logging call blocks until enought memory space is available again, achieved through a
        /// partial completed uploading of log data, resulting in freed temporary buffers.
        /// In practice, approaching the maximumTotalLogStorageSize should basically never happen,
        /// except in very resource restricted environments.
        public var maximumTotalLogStorageSize: Int = 4_194_304
        
        /// Used to log background activity of the transport and `HTTPClient`.
        /// This logger MUST be created BEFORE the `LoggingSystem` is bootstrapped, else it results in an infinte recusion!
        public var backgroundActivityLogger: Logger
        
        /// What fields of the event must be part of the `metadata` field of the logstash body representation.
        /// By default the `extra` is used (only `String` convertible data).
        /// NOTE: If you set both `extra` and `tags`, `tags` may override existing `extra` values when there are conflicts.
        public var logstashMetadataSources: [MetadataOrigin] = [.extra]
        
        /// Minumum accepted level for this transport.
        /// `nil` means every passing message level is accepted.
        public var minimumAcceptedLevel: Level?
        
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
        
        // MARK: - Initialization
        
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
            self.queue = DispatchQueue(label: String(describing: type(of: self)), attributes: [])
            
            self.backgroundActivityLogger = Logger(label: "backgroundActivity-logstashHandler")
            
            builder?(&self)
            
            // Validate data
            
            // If the double minimum log storage size is larger than maximum log storage size throw error
            if maximumTotalLogStorageSize.nextPowerOf2() < (2 * logStorageSize.nextPowerOf2()) {
                // swiftlint:disable line_length
                throw GliderError(message: "maximumLogStorageSize needs to be at least twice as much (spoken in terms of the power of two) as the passed minimumLogStorageSize.")
            }
            
            // Round up to the power of two since ByteBuffer automatically allocates in these steps
            logStorageSize = logStorageSize.nextPowerOf2()
            maximumTotalLogStorageSize = maximumTotalLogStorageSize.nextPowerOf2()
        }
        
    }
    
}

extension GliderELKTransport.Configuration {
    
    /// What kind of fields must be part of sent metadata in logstash.
    ///
    /// NOTE:
    /// Tags may replace extra because have an higher priority.
    ///
    /// - `extra`: the `allExtra` property is used (only `String` representable data).
    /// - `tags`: the `allTags` property is used (all values).
    public enum MetadataOrigin {
        case extra
        case tags
    }
    
}
