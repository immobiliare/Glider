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
    
    /// The max number of items that will be stored in the receiver's buffer.
    public let bufferLimit: Int
    
    /// The function used to create a `BufferItem` given a `Event` instance.
    public let bufferedItemBuilder: BufferItemBuilder
    
    /// Formatters used to convert messages to strings.
    public let formatters: [EventFormatter]
    
    /// Dispatch queue where the record happens.
    public let queue: DispatchQueue?
    
    /// The buffer, an array of `BufferItem` created to represent the
    /// `Event` values recorded by the receiver.
    open private(set) var buffer = [BufferItem]()
    
    // MARK: - Initialization
    
    /// Initializes a new buffered transport recorder.
    ///
    /// - Parameters:
    ///   - bufferLimit: If this value is positive, it specifies the
    ///                  maximum number of items to store in the buffer. If `record(event: )` is called
    ///                  when the buffer limit has been reached, the oldest item in the buffer will
    ///                  be dropped. If this value is zero or negative, no limit will be applied.
    ///
    ///                  Note:
    ///                  that this is potentially dangerous in production code, since memory
    ///                  consumption will grow endlessly unless you manually clear the buffer periodically.
    ///   - formatters: formatters used to transform the event into `SerializableData` conform object.
    ///   - queue: The `DispatchQueue` to use for the recorder. If `nil` a new queue will be created.
    ///   - builder: The function used to create `BufferItem` instances for each `Event` and formatted
    ///              message string passed to the receiver's `record`(event: )` function.
    public init(bufferLimit: Int = 10_000,
                formatters: [EventFormatter],
                queue: DispatchQueue? = nil,
                builder: @escaping BufferItemBuilder) {
        self.bufferLimit = bufferLimit
        self.formatters = formatters
        self.queue = queue ?? DispatchQueue(label: String(describing: type(of: self)))
        self.bufferedItemBuilder = builder
    }
    
    // MARK: - Conformance
    
    public func record(event: Event) -> Bool {
        guard let message = formatters.format(event: event) else {
            return false
        }
        
        let item = bufferedItemBuilder(event, message)
        buffer.append(item)

        if bufferLimit > 0 && buffer.count > bufferLimit {
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
