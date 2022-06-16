// This method contains most of the public API and extensive documentation
// The 400 line limit doesn't make sense here
// swiftlint:disable file_length

import Foundation

public enum MessagePackReaderError: Error {
    /// The unpacked type is not supported by this library
    case unknownType(rawByte: UInt8)

    /// The MessagePack value's type doesn't match the requested one
    case typeMismatch(found: String)

    /// The message's data's end has been reached, not enough bytes were available
    /// to read the requested type
    case messageEndReached

    /// The value could not be unpacked in the container.
    /// This is used for Numerics, where you might try to unpack a Int32 but
    /// an Int64 was encountered and is not represeentable in 32 bytes,
    /// or trying to unpack a negative integer in a UInt.
    case inappropriateContainer

    /// The dictionary entry's key was not hashable.
    /// This library does not support unpacking all MessagePack values as
    /// dictionary keys, as they need to conform to AnyHashable.
    /// If you're encountering this error, unpack the dictionary manually.
    case unhashableKey

    /// The string could not be decoded.
    case undecodableString

    case notImplemented
}

/// Reads a MessagePack payload.
/// Reading happens sequentially, as methods consume the wrapped data.
/// Note: read methods that throw leave the reader in an undefined state.
/// Do NOT try to resume reading after an error has been thrown.
public struct MessagePackReader {
    private var stream: DataStreamReader

    public init(from data: Data) {
        stream = DataStreamReader(from: data)
    }
}

internal extension MessagePackReader {
    /// Try to consume a nil value.
    /// If the upcoming value isn't nil, the stream won't be advanced.
    /// - Returns: True if a nil value was found and consumed, false if not.
    mutating func tryConsumeNil() throws -> Bool {
        let type = try MessagePackType.from(stream.peekByte())
        if case .nil = type {
            stream.skipByte()
            return true
        }
        return false
    }

    /// Read a uint8/16/36/64 or int8/16/32/64 into a Int64.
    /// - Returns: the int64 representation of the integer
    /// - Throws: MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    ///           MessagePackReaderError.typeMismatch if the value wasn't an integer
    mutating func readInteger() throws -> Int64 {
        let type = try MessagePackType.from(stream.readByte())
        switch type {
            case let .negativeFixedInt(value):
                return Int64(value)
            case let .positiveFixedInt(value):
                return Int64(value)
            case .int8:
                return Int64(try stream.read(Int8.self))
            case .int16:
                return Int64(try stream.read(Int16.self))
            case .int32:
                return Int64(try stream.read(Int32.self))
            case .int64:
                return try stream.read(Int64.self)
            case .uint8:
                return Int64(try stream.read(UInt8.self))
            case .uint16:
                return Int64(try stream.read(UInt16.self))
            case .uint32:
                return Int64(try stream.read(UInt32.self))
            case .uint64:
                if let int = Int64(exactly: try stream.read(UInt64.self)) {
                    return int
                }
                throw MessagePackReaderError.inappropriateContainer
            default:
                throw MessagePackReaderError.typeMismatch(found: type.description)
        }
    }

    /// Read a uint8/16/36/64 or int8/16/32/64 into a UInt64.
    /// - Returns: the int64 representation of the integer
    /// - Throws: MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    ///           MessagePackReaderError.typeMismatch if the value wasn't an integer
    mutating func readUnsignedInteger() throws -> UInt64 {
        let type = try MessagePackType.from(stream.readByte())
        switch type {
            case .negativeFixedInt:
                throw MessagePackReaderError.inappropriateContainer
            case let .positiveFixedInt(value):
                return UInt64(value)
            case .int8:
                return try fitInUInt(try stream.read(Int8.self))
            case .int16:
                return try fitInUInt(try stream.read(Int16.self))
            case .int32:
                return try fitInUInt(try stream.read(Int32.self))
            case .int64:
                return try fitInUInt(try stream.read(Int64.self))
            case .uint8:
                return UInt64(try stream.read(UInt8.self))
            case .uint16:
                return UInt64(try stream.read(UInt16.self))
            case .uint32:
                return UInt64(try stream.read(UInt32.self))
            case .uint64:
                return try stream.read(UInt64.self)
            default:
                throw MessagePackReaderError.typeMismatch(found: type.description)
        }
    }

    /// Simple UInt64 cast helper
    @inlinable
    func fitInUInt<T: BinaryInteger>(_ value: T) throws -> UInt64 {
        if let uint = UInt64(exactly: value) {
            return uint
        }
        throw MessagePackReaderError.inappropriateContainer
    }
}

// MARK: Public API - Strongly typed readers

public extension MessagePackReader {
    /// Read a nil value.
    /// - Throws: MessagePackReaderError if the value could not be unpacked
    mutating func readNil() throws {
        let type = try MessagePackType.from(stream.readByte())
        if case .nil = type {
            return
        }
        throw MessagePackReaderError.typeMismatch(found: type.description)
    }

    /// Read a boolean.
    /// - Returns: The unpacked value
    /// - Throws: MessagePackReaderError if the value could not be unpacked
    mutating func read(_: Bool.Type) throws -> Bool {
        let type = try MessagePackType.from(stream.readByte())
        if case let .boolean(value) = type {
            return value
        }
        throw MessagePackReaderError.typeMismatch(found: type.description)
    }

    /// Read a Int8.
    /// - Returns: The unpacked value
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: Int8.Type) throws -> Int8 {
        if let int = Int8(exactly: try readInteger()) {
            return int
        }
        throw MessagePackReaderError.inappropriateContainer
    }

    /// Read a Int16.
    /// - Returns: The unpacked value
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: Int16.Type) throws -> Int16 {
        if let int = Int16(exactly: try readInteger()) {
            return int
        }
        throw MessagePackReaderError.inappropriateContainer
    }

    /// Read a Int32.
    /// - Returns: The unpacked value
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: Int32.Type) throws -> Int32 {
        if let int = Int32(exactly: try readInteger()) {
            return int
        }
        throw MessagePackReaderError.inappropriateContainer
    }

    /// Read a Int64.
    /// - Returns: The unpacked value
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: Int64.Type) throws -> Int64 {
        if let int = Int64(exactly: try readInteger()) {
            return int
        }
        throw MessagePackReaderError.inappropriateContainer
    }

    /// Read a Int.
    /// - Returns: The unpacked value
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: Int.Type) throws -> Int {
        if let int = Int(exactly: try readInteger()) {
            return int
        }
        throw MessagePackReaderError.inappropriateContainer
    }

    /// Read a UInt8.
    /// - Returns: The unpacked value
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: UInt8.Type) throws -> UInt8 {
        if let uint = UInt8(exactly: try readUnsignedInteger()) {
            return uint
        }
        throw MessagePackReaderError.inappropriateContainer
    }

    /// Read a UInt16.
    /// - Returns: The unpacked value
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: UInt16.Type) throws -> UInt16 {
        if let uint = UInt16(exactly: try readUnsignedInteger()) {
            return uint
        }
        throw MessagePackReaderError.inappropriateContainer
    }

    /// Read a UInt32.
    /// - Returns: The unpacked value
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: UInt32.Type) throws -> UInt32 {
        if let uint = UInt32(exactly: try readUnsignedInteger()) {
            return uint
        }
        throw MessagePackReaderError.inappropriateContainer
    }

    /// Read a UInt64.
    /// - Returns: The unpacked value
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: UInt64.Type) throws -> UInt64 {
        if let uint = UInt64(exactly: try readUnsignedInteger()) {
            return uint
        }
        throw MessagePackReaderError.inappropriateContainer
    }

    /// Read a UInt.
    /// - Returns: The unpacked value
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: UInt.Type) throws -> UInt {
        if let uint = UInt(exactly: try readUnsignedInteger()) {
            return uint
        }
        throw MessagePackReaderError.inappropriateContainer
    }

    /// Read a Float/Float32.
    /// A packed Double value is not unpackable and will throw an error.
    /// - Returns: The unpacked value
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number wasn't a float.
    mutating func read(_: Float.Type) throws -> Float {
        let type = try MessagePackType.from(stream.readByte())
        switch type {
            case .float32:
                return Float(bitPattern: try stream.read(UInt32.self))
            case .float64:
                throw MessagePackReaderError.inappropriateContainer
            default:
                throw MessagePackReaderError.typeMismatch(found: type.description)
        }
    }

    /// Read a Double/Float64.
    /// A packed Float value will be converted into a Double.
    /// - Returns: The unpacked value
    /// - Throws: MessagePackReaderError if the value could not be unpacked
    mutating func read(_: Double.Type) throws -> Double {
        let type = try MessagePackType.from(stream.readByte())
        switch type {
            case .float32:
                return Double(Float(bitPattern: try stream.read(UInt32.self)))
            case .float64:
                return Double(bitPattern: try stream.read(UInt64.self))
            default:
                throw MessagePackReaderError.typeMismatch(found: type.description)
        }
    }

    /// Read a String.
    /// - Returns: The unpacked value
    /// - Throws: MessagePackReaderError if the value could not be unpacked
    mutating func read(_: String.Type) throws -> String {
        let type = try MessagePackType.from(stream.readByte())
        var lengthToRead: UInt
        switch type {
            case let .fixedStr(size):
                lengthToRead = UInt(size)
            case .str8:
                lengthToRead = UInt(try stream.read(UInt8.self))
            case .str16:
                lengthToRead = UInt(try stream.read(UInt16.self))
            case .str32:
                lengthToRead = UInt(try stream.read(UInt32.self))
            default:
                throw MessagePackReaderError.typeMismatch(found: type.description)
        }
        let bytes = try stream.readBytes(count: lengthToRead)
        guard let result = String(bytes: bytes, encoding: .utf8) else {
            throw MessagePackReaderError.undecodableString
        }
        return result
    }

    /// Read a Data.
    /// - Returns: The unpacked value
    /// - Throws: MessagePackReaderError if the value could not be unpacked
    mutating func read(_: Data.Type) throws -> Data {
        let type = try MessagePackType.from(stream.readByte())
        var lengthToRead: UInt
        switch type {
            case .bin8:
                lengthToRead = UInt(try stream.read(UInt8.self))
            case .bin16:
                lengthToRead = UInt(try stream.read(UInt16.self))
            case .bin32:
                lengthToRead = UInt(try stream.read(UInt32.self))
            default:
                throw MessagePackReaderError.typeMismatch(found: type.description)
        }
        return try stream.readBytes(count: lengthToRead)
    }

    /// Read an dictionary's header and return its length. Does not attempt to read the dictionary.
    /// - Throws: MessagePackReaderError if the value could not be unpacked
    mutating func readDictionaryHeader() throws -> UInt {
        let type = try MessagePackType.from(stream.readByte())
        switch type {
            case let .fixedMap(size):
                return UInt(size)
            case .map16:
                return UInt(try stream.read(UInt16.self))
            case .map32:
                return UInt(try stream.read(UInt32.self))
            default:
                throw MessagePackReaderError.typeMismatch(found: type.description)
        }
    }

    /// Read a dictionary
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.unhashableKey if a key isn't AnyHashable.
    mutating func readDictionary() throws -> [AnyHashable: Any?] {
        let dictLength = try readDictionaryHeader()
        var resultDict: [AnyHashable: Any?] = [:]
        for _ in 0 ..< dictLength {
            guard let key = try readAny() as? AnyHashable else {
                throw MessagePackReaderError.unhashableKey
            }
            resultDict[key] = try readAny()
        }
        return resultDict
    }

    /// Read a dictionary by mapping the values to a complex object manually.
    /// - Parameter mapClosure: The closure that will be ran to map the flat values to
    ///                         a key/object.
    /// - Throws: MessagePackReaderError if the value could not be unpacked
    mutating func readAndMapDictionary<T>(_ mapClosure: (inout MessagePackReader) throws -> (AnyHashable, T)) throws -> [AnyHashable: T] {
        // swiftlint:disable:previous line_length
        let dictLength = try readDictionaryHeader()
        var resultDict: [AnyHashable: T] = [:]
        for _ in 0 ..< dictLength {
            let (key, value) = try mapClosure(&self)
            resultDict[key] = value
        }
        return resultDict
    }

    /// Read an array's header and return its length. Does not attempt to read the array.
    /// - Throws: MessagePackReaderError if the value could not be unpacked
    mutating func readArrayHeader() throws -> UInt {
        let type = try MessagePackType.from(stream.readByte())
        switch type {
            case let .fixedArray(size):
                return UInt(size)
            case .array16:
                return UInt(try stream.read(UInt16.self))
            case .array32:
                return UInt(try stream.read(UInt32.self))
            default:
                throw MessagePackReaderError.typeMismatch(found: type.description)
        }
    }

    /// Read an array.
    /// See readAny(_:) for how values are decoded.
    /// - Throws: MessagePackReaderError if the value could not be unpacked
    mutating func readArray() throws -> [Any?] {
        let arrayLength = try readArrayHeader()
        var resultArray: [Any?] = []
        for _ in 0 ..< arrayLength {
            resultArray.append(try readAny())
        }
        return resultArray
    }

    /// Read an array by mapping the values to a complex object manually.
    /// - Parameter mapClosure: The closure that will be ran to map the flat values to
    ///                         an object.
    /// - Throws: MessagePackReaderError if the value could not be unpacked
    mutating func readAndMapArray<T>(_ mapClosure: (inout MessagePackReader) throws -> T) throws -> [T] {
        let arrayLength = try readArrayHeader()
        var resultArray: [T] = []
        for _ in 0 ..< arrayLength {
            resultArray.append(try mapClosure(&self))
        }
        return resultArray
    }

    /// Read any value.
    /// Supported values are:
    ///     Nil,
    ///     Bool,
    ///     UInt64 (only UInts that does not fit into a Int64),
    ///     Int64 (any UInt8/16/32 and Int* value will be uppercasted to Int64 for simplicity),
    ///     Float,
    ///     Double,
    ///     String,
    ///     Data,
    ///     [Any?],
    ///     [AnyHashable: Any?]
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.unknownType for unpackable types.
    mutating func readAny() throws -> Any? {
        let type = try MessagePackType.from(stream.peekByte())
        switch type {
            case .nil:
                stream.skipByte()
                return nil
            case let .boolean(value):
                stream.skipByte()
                return value
            case let .positiveFixedInt(value):
                stream.skipByte()
                return Int64(value)
            case let .negativeFixedInt(value):
                stream.skipByte()
                return Int64(value)
            case .int8, .int16, .int32, .int64, .uint8, .uint16, .uint32: return try read(Int64.self)
            case .uint64: return try read(UInt64.self)
            case .float32: return try read(Float.self)
            case .float64: return try read(Double.self)
            case .fixedStr, .str8, .str16, .str32: return try read(String.self)
            case .bin8, .bin16, .bin32: return try read(Data.self)
            case .fixedArray, .array16, .array32: return try readArray()
            case .fixedMap, .map16, .map32: return try readDictionary()
        }
    }

    /// Unsafely peek a byte.
    /// This method doesn't consume the byte, it must be read again to advance the stream.
    /// - Returns: the read byte
    /// - Throws: MessagePackReaderError.endReached if there are not enough bytes available to consume
    mutating func unsafePeekRawByte() throws -> UInt8 {
        try stream.peekByte()
    }

    /// Unsafely read raw data.
    /// This method consumes the bytes. If you need to rewind, copy the reader first.
    /// - Parameter length: How many bytes to read
    /// - Returns: the read bytes
    /// - Throws: MessagePackReaderError.endReached if there are not enough bytes available to consume
    mutating func unsafeReadRawData(_ length: UInt) throws -> Data {
        try stream.readBytes(count: length)
    }
}
