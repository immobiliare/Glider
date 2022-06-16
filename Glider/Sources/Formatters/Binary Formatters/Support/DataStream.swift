import Foundation

/// Allows to read a Data value like a stream
/// InputStream can do this job but it's far too complicated for our needs
internal struct DataStreamReader {
    private let data: Data
    private let availableBytes: Int
    private var offset: Int // Current byte index

    /// Create a DataStreamReader from data
    init(from: Data) {
        data = from
        availableBytes = from.count
        offset = 0
    }

    /// Read a byte
    /// - Throws: DataStreamReaderError.endReached if no bytes were left to be read
    internal mutating func readByte() throws -> UInt8 {
        try throwIfNotEnoughData()
        let byte = data[offset]
        offset += 1
        return byte
    }

    /// Read multiple bytes
    /// - Throws: DataStreamReaderError.endReached if no bytes were left to be read
    internal mutating func readBytes(count: UInt) throws -> Data {
        try throwIfNotEnoughData(lengthToBeRead: count)
        let baseOffset = offset
        offset += Int(count)
        return data.subdata(in: baseOffset ..< offset)
    }

    /// Peek a byte (Doesn't consume the byte that it just read)
    internal func peekByte() throws -> UInt8 {
        try throwIfNotEnoughData()
        return data[offset]
    }

    /// Skip a byte
    internal mutating func skipByte() {
        offset += 1
    }

    /// Checks if the underlying data has enough bytes to be read
    /// - Parameter lengthToBeRead: Length the reader needs from the data
    /// - Throws: DataStreamReaderError.endReached if the data doesn't have
    ///           enough bytes to satisfy the reader
    private func throwIfNotEnoughData(lengthToBeRead: UInt = 1) throws {
        if offset + Int(lengthToBeRead) > availableBytes {
            throw MessagePackReaderError.messageEndReached
        }
    }
}

// MARK: Numeric extensions

extension DataStreamReader {
    @inlinable
    internal mutating func read(_: UInt8.Type) throws -> UInt8 {
        try readByte()
    }

    @inlinable
    internal mutating func read(_: UInt16.Type) throws -> UInt16 {
        let bytes = try readBytes(count: 2)
        return bytes.withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
    }

    @inlinable
    internal mutating func read(_: UInt32.Type) throws -> UInt32 {
        let bytes = try readBytes(count: 4)
        return bytes.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
    }

    @inlinable
    internal mutating func read(_: UInt64.Type) throws -> UInt64 {
        let bytes = try readBytes(count: 8)
        return bytes.withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
    }

    @inlinable
    internal mutating func read(_: Int8.Type) throws -> Int8 {
        let byte = try readByte()
        return Int8(bitPattern: byte)
    }

    @inlinable
    internal mutating func read(_: Int16.Type) throws -> Int16 {
        let bytes = try readBytes(count: 2)
        return bytes.withUnsafeBytes { $0.load(as: Int16.self).bigEndian }
    }

    @inlinable
    internal mutating func read(_: Int32.Type) throws -> Int32 {
        let bytes = try readBytes(count: 4)
        return bytes.withUnsafeBytes { $0.load(as: Int32.self).bigEndian }
    }

    @inlinable
    internal mutating func read(_: Int64.Type) throws -> Int64 {
        let bytes = try readBytes(count: 8)
        return bytes.withUnsafeBytes { $0.load(as: Int64.self).bigEndian }
    }
}
