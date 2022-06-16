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

/// The `BufferedTransport` is a generic event recorder that buffers the log
/// messages passed to its `record(event:)` function.
///
/// Construction requires a `bufferedItemBuilder` function, which is responsible
/// for converting the `event` and formatted message `SerializableData` into the
/// generic `BufferItem` type.
public class BufferedTransport<BufferItem>: Transport {
    public typealias BufferItemBuilder = (Event, SerializableData) -> BufferItem
    
    // MARK: - Public Functions
    
    /// Configuration.
    public let configuration: Configuration
    
    /// Transport is enabled.
    public var isEnabled: Bool = true
    
    /// Dispatch queue where the record happens.
    public let queue: DispatchQueue?
    
    /// The buffer, an array of `BufferItem` created to represent the
    /// `Event` values recorded by the receiver.
    open private(set) var buffer = [BufferItem]()
    
    // MARK: - Initialization
    
    /// Initializer a new `BufferedTransport`.
    ///
    /// - Parameters:
    ///   - bufferedItemBuilder: The function used to create a `BufferItem` given a `Event` instance.
    ///   - builder: builder function to setup additional settings.
    public init(bufferedItemBuilder: @escaping BufferItemBuilder,
                _ builder: ((inout Configuration) -> Void)) {
        self.configuration = Configuration(bufferedItemBuilder: bufferedItemBuilder, builder)
        self.queue = configuration.queue
    }
    
    // MARK: - Conformance
    
    public func record(event: Event) -> Bool {
        guard isEnabled else { return false }
        
        guard let message = configuration.formatters.format(event: event) else {
            return false
        }
        
        let item = configuration.bufferedItemBuilder(event, message)
        buffer.append(item)

        if configuration.bufferLimit > 0 && buffer.count > configuration.bufferLimit {
            buffer.remove(at: 0)
        }
        
        return true
    }
    
    // MARK: - Public Functions
    
    /// Clears the contents of the buffer.
    ///
    /// NOTE:
    /// This operation is performed synchronously on the receiver's `queue`
    /// to ensure thread safety.
    public func clear() {
        queue!.sync { // prevents race conditions
            self.buffer = []
        }
    }
        
}

// MARK: - Configuration

extension BufferedTransport {
    
    public struct Configuration {
        
        // MARK: - Public Properties
        
        /// The max number of items that will be stored in the receiver's buffer (default is 500).
        ///
        /// If this value is positive, it specifies the
        /// maximum number of items to store in the buffer. If `record(event: )` is called
        /// when the buffer limit has been reached, the oldest item in the buffer will
        /// be dropped. If this value is zero or negative, no limit will be applied.
        ///
        /// Note:
        /// that this is potentially dangerous in production code, since memory
        /// consumption will grow endlessly unless you manually clear the buffer periodically.
        public var bufferLimit: Int = 500
        
        /// The function used to create a `BufferItem` given a `Event` instance.
        public var bufferedItemBuilder: BufferItemBuilder
        
        /// Formatters used to convert messages to strings.
        public var formatters = [EventFormatter]()
        
        /// Dispatch queue where the record happens.
        public var queue = DispatchQueue(label: "Glider.\(UUID().uuidString)")

        // MARK: - Initialization
        
        /// Initialize a new `BufferedTransport` with configuration.
        ///
        /// - Parameter builder: builder configuration
        public init(bufferedItemBuilder: @escaping BufferItemBuilder, _ builder: ((inout Configuration) -> Void)) {
            self.bufferedItemBuilder = bufferedItemBuilder
            builder(&self)
        }
        
    }
    
}
