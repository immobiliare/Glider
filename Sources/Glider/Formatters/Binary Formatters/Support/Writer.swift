// This method contains most of the public API and extensive documentation
// The 400 line limit doesn't make sense here
// swiftlint:disable file_length

import Foundation

enum MessagePackWriterError: Error {
    case stringTooBig
    case dataTooBig
    case arrayTooBig
    case dictionaryTooBig
    case invalidArgument
    case unsupportedType(type: String)
}

/// Handles packing data in a MsgPack message. Once done, just read the `data` property.
/// There is no need to close or free anything.
///
/// Example:
/// ```
/// let writer: MessagePackWriter()
/// writer.pack("foo")
/// writer.pack(20)
/// writer.pack([2,3,4])
/// writer.pack(["foo": "bar"])
/// let data = writer.data
/// ```
public struct MessagePackWriter {
    // Hidden variable to work around the inability to have public(@usableFromInline set)
    // swiftlint:disable:next identifier_name
    @usableFromInline internal var _data = Data()

    public init() {}
}

// Helpers
extension MessagePackWriter {
    @inlinable
    internal mutating func write<T: FixedWidthInteger>(integer: T) {
        var bigEndianInteger = integer.bigEndian
        withUnsafeBytes(of: &bigEndianInteger) {
            let buffer = $0.bindMemory(to: T.self)
            _data.append(buffer)
        }
    }
}

// MARK: Integer packing

extension MessagePackWriter {
    // Pack a value as a int64
    // Note: this metod does not check if the value could be packed into a smaller type
    @inlinable
    internal mutating func pack(int64 value: Int64) {
        _data.append(MessagePackType.int64.headerValue)
        write(integer: value)
    }

    // Pack a value as a int32
    // Note: this metod does not check if the value could be packed into a smaller type
    @inlinable
    internal mutating func pack(int32 value: Int32) {
        _data.append(MessagePackType.int32.headerValue)
        write(integer: value)
    }

    // Pack a value as a int16
    // Note: this metod does not check if the value could be packed into a smaller type
    @inlinable
    internal mutating func pack(int16 value: Int16) {
        _data.append(MessagePackType.int16.headerValue)
        write(integer: value)
    }

    // Pack a value as a int8
    // This method will inline the int if possible
    @inlinable
    internal mutating func pack(int8 value: Int8) {
        if value >= 0 {
            pack(uint8: UInt8(value))
            return
        }
        // Negative integer
        // Inlining only works from -32 to -1. (MsgPack encodes small negative values as 111XXXXX)
        if value >= -32 {
            _data.append(MessagePackType.negativeFixedInt(value).headerValue)
            return
        }
        _data.append(MessagePackType.int8.headerValue)
        write(integer: value)
    }

    // Pack a value as a uint64
    // Note: this metod does not check if the value could be packed into a smaller type
    @inlinable
    internal mutating func pack(uint64 value: UInt64) {
        _data.append(MessagePackType.uint64.headerValue)
        write(integer: value)
    }

    // Pack a value as a uint32
    // Note: this metod does not check if the value could be packed into a smaller type
    @inlinable
    internal mutating func pack(uint32 value: UInt32) {
        _data.append(MessagePackType.uint32.headerValue)
        write(integer: value)
    }

    // Pack a value as a uint16
    // Note: this metod does not check if the value could be packed into a smaller type
    @inlinable
    internal mutating func pack(uint16 value: UInt16) {
        _data.append(MessagePackType.uint16.headerValue)
        write(integer: value)
    }

    // Pack a value as a uint8
    // This method will inline the uint if possible
    @inlinable
    internal mutating func pack(uint8 value: UInt8) {
        // Inlining only works from 0 to 127. (MsgPack encodes small positive values as 0XXXXXXX)
        if value <= 127 {
            _data.append(MessagePackType.positiveFixedInt(value).headerValue)
            return
        }
        _data.append(MessagePackType.uint8.headerValue)
        write(integer: value)
    }
}

// MARK: Public API

public extension MessagePackWriter {
    /// Currently packed data
    var data: Data { _data }

    /// Pack a nil value.
    mutating func packNil() {
        _data.append(MessagePackType.nil.headerValue)
    }

    /// Pack a boolean value.
    /// - Parameter value: Boolean value
    mutating func pack(_ value: Bool) {
        _data.append(MessagePackType.boolean(value).headerValue)
    }

    /// Pack an integer.
    /// This method will automatically use the most compact way to pack the value.
    /// Prefer this method to pack(int8:) pack(int16:) etc.
    /// For 32 bit platforms, pack(int64:) might be useful.
    /// - Parameter value: Integer value
    mutating func pack<T: BinaryInteger>(_ value: T) {
        if value >= 0 {
            if let value8 = UInt8(exactly: value) {
                pack(uint8: value8)
                return
            }
            if let value16 = UInt16(exactly: value) {
                pack(uint16: value16)
                return
            }
            if let value32 = UInt32(exactly: value) {
                pack(uint32: value32)
                return
            }
            pack(uint64: UInt64(value))
            return
        }
        if let value8 = Int8(exactly: value) {
            pack(int8: value8)
            return
        }
        if let value16 = Int16(exactly: value) {
            pack(int16: value16)
            return
        }
        if let value32 = Int32(exactly: value) {
            pack(int32: value32)
            return
        }
        pack(int64: Int64(value))
    }

    /// Pack a double. Also known as float64.
    /// This method will automatically use the most compact way to pack the value.
    /// - Parameter value: Double/Float64 value
    mutating func pack(_ value: Double) {
        _data.append(MessagePackType.float64.headerValue)
        var bigEndianBitPattern = value.bitPattern.bigEndian
        withUnsafeBytes(of: &bigEndianBitPattern) {
            let buffer = $0.bindMemory(to: Double.self)
            _data.append(buffer)
        }
    }

    /// Pack a double. Also known as float32.
    /// This method will automatically use the most compact way to pack the value.
    /// - Parameter value: Float/Float32 value
    mutating func pack(_ value: Float) {
        _data.append(MessagePackType.float32.headerValue)
        var bigEndianBitPattern = value.bitPattern.bigEndian
        withUnsafeBytes(of: &bigEndianBitPattern) {
            let buffer = $0.bindMemory(to: Float.self)
            _data.append(buffer)
        }
    }

    /// Pack a String.
    /// - Parameter value: String value
    /// - Throws: throws MessagePackWriterError.stringTooBig if the
    ///           utf-8 representation of the string is longer than 2^32-1 bytes.
    mutating func pack(_ value: String) throws {
        // Do not use String's count method, which returns the number of characters
        // Instead, get the string's utf8 view
        let utf8value = value.utf8
        let length = utf8value.count

        if let length8 = UInt8(exactly: length) {
            if length8 <= 31 {
                _data.append(MessagePackType.fixedStr(size: length8).headerValue)
            } else {
                _data.append(MessagePackType.str8.headerValue)
                write(integer: length8)
            }
        } else if let length16 = UInt16(exactly: length) {
            _data.append(MessagePackType.str16.headerValue)
            write(integer: length16)
        } else if let length32 = UInt32(exactly: length) {
            _data.append(MessagePackType.str32.headerValue)
            write(integer: length32)
        } else {
            throw MessagePackWriterError.stringTooBig
        }
        _data.append(Data(utf8value))
    }

    /// Pack a Data stuct.
    /// - Parameter value: Data value
    /// - Throws: throws MessagePackWriterError.dataTooBig if the data is bigger than 2^32-1 bytes.
    mutating func pack(_ value: Data) throws {
        // Data(bin) header is:
        //  0xc4/0xc5/0xc6
        //  8/16/32 bytes representing the size of the byte array
        //  the actual byte array
        let length = value.count
        if let length8 = UInt8(exactly: length) {
            _data.append(MessagePackType.bin8.headerValue)
            write(integer: length8)
        } else if let length16 = UInt16(exactly: length) {
            _data.append(MessagePackType.bin16.headerValue)
            write(integer: length16)
        } else if let length32 = UInt32(exactly: length) {
            _data.append(MessagePackType.bin32.headerValue)
            write(integer: length32)
        } else {
            throw MessagePackWriterError.dataTooBig
        }

        _data.append(value)
    }

    /// Pack an array header only.
    /// Most of the time, you will want to write an array using pack(_: [Any?])
    /// This method allows you to pack arrays manually, meaning
    /// that the array count represents the number of complex messages to unpack serially,
    /// rather than the absolute number of messagepack values.
    /// The parser should expect this kind of array, which cannot be unpacked
    /// using a generic method.
    ///
    /// Example:
    /// ```
    /// let packer = MessagePackWriter()
    /// packer.packArrayHeader(count: 2)
    /// packer.pack("foo") // First Object
    /// packer.pack(2)
    /// packer.pack("bar") // Second object
    /// ```
    ///
    /// - Parameter count: Number of elements that the array will contain
    /// - Throws: throws MessagePackWriterError.arrayTooBig if the array is longer than 2^32-1 elements.
    ///           throws MessagePackWriterError.invalidArgument if count is < 0
    /// - Note: You can also use packFlatArray(_ array: [MessagePackFlatValue])
    mutating func packArrayHeader(count: Int) throws {
        // 8-bit values are not supported, only inlining.
        if count < 0 {
            throw MessagePackWriterError.invalidArgument
        }
        if count <= 15, let length8 = UInt8(exactly: count) {
            _data.append(MessagePackType.fixedArray(size: length8).headerValue)
        } else if let length16 = UInt16(exactly: count) {
            _data.append(MessagePackType.array16.headerValue)
            write(integer: length16)
        } else if let length32 = UInt32(exactly: count) {
            _data.append(MessagePackType.array32.headerValue)
            write(integer: length32)
        } else {
            throw MessagePackWriterError.arrayTooBig
        }
    }

    /// Pack a flat array.
    /// A flat array is an array where the count doesn't exactly match the MessagePack
    /// objects, but rather the number of complex MessagePack objects, which
    /// might be made of multiple consecutive primitive objects.
    ///
    /// Note: No checks are made on the packed values, they will be packed as-is.
    ///
    /// It must be composed of MessagePackFlatValue.
    /// - Parameter value: Array of MessagePackFlatValue to pack
    /// - Throws: throws MessagePackWriterError.arrayTooBig if the array is longer than 2^32-1 elements
    mutating func packFlatArray(_ array: [MessagePackFlatValue]) throws {
        try packArrayHeader(count: array.count)
        array.forEach { _data.append($0.data) }
    }

    /// Pack an array.
    /// See pack(_: Any?) for supported values. MessagePackFlatValue is not supported here.
    /// If the method throws, the array will not be written at all so you can safely recover from the error.
    /// - Parameter value: Array of Any?, where Any must be a packable type.
    ///                    MessagePackFlatValue is not supported.
    /// - Throws: throws MessagePackWriterError.arrayTooBig if the array is longer than 2^32-1 elements.
    ///           throws MessagePackWriterError.unsupportedType if the array contains an unpackable value.
    mutating func pack(_ value: [Any?]) throws {
        try packArrayHeader(count: value.count)

        // Use another writer so we don't write anything until we're sure the array only has supported values,
        // allowing us to throw without destroying the payload.
        var arrayWriter = MessagePackWriter()
        try value.forEach { try arrayWriter.packAny($0) }
        _data.append(arrayWriter.data)
    }

    /// Pack an dictionary header only.
    /// Most of the time, you will want to write an dictionary using pack(_: [Any?])
    /// This method allows you to pack dictionaries manually, meaning
    /// that the dictionary count represents the number of complex messages to unpack serially,
    /// rather than the absolute number of messagepack values.
    /// The parser should expect this kind of dictionary, which cannot be unpacked
    /// using a generic method.
    ///
    /// - Parameter count: Number of elements that the dictionary will contain
    /// - Throws: throws MessagePackWriterError.arrayTooBig if the array is longer than 2^32-1 elements.
    ///           throws MessagePackWriterError.invalidArgument if count is < 0
    /// - Note: You can also use pack(_ value: [AnyHashable: MessagePackFlatValue])
    mutating func packDictionaryHeader(count: Int) throws {
        // 8-bit values are not supported, only inlining.
        if count < 0 {
            throw MessagePackWriterError.invalidArgument
        }
        // 8-bit values are not supported, only inlining.
        if count <= 15, let length8 = UInt8(exactly: count) {
            _data.append(MessagePackType.fixedMap(size: length8).headerValue)
        } else if let length16 = UInt16(exactly: count) {
            _data.append(MessagePackType.map16.headerValue)
            write(integer: length16)
        } else if let length32 = UInt32(exactly: count) {
            _data.append(MessagePackType.map32.headerValue)
            write(integer: length32)
        } else {
            throw MessagePackWriterError.dictionaryTooBig
        }
    }

    /// Pack a flat array.
    /// A flat array is an array where the count doesn't exactly match the MessagePack
    /// objects, but rather the number of complex MessagePack objects, which
    /// might be made of multiple consecutive primitive objects.
    ///
    /// Note: No checks are made on the packed values, they will be packed as-is.
    ///
    /// It must be composed of MessagePackFlatValue.
    /// - Parameter value: Array of MessagePackFlatValue to pack
    /// - Throws: throws MessagePackWriterError.arrayTooBig if the array is longer than 2^32-1 elements
    mutating func packFlatDictionary(_ dictionary: [AnyHashable: MessagePackFlatValue]) throws {
        try packDictionaryHeader(count: dictionary.count)
        for (key, value) in dictionary {
            try packAny(key)
            _data.append(value.data)
        }
    }

    /// Pack a dictionary.
    /// See pack(_: Any?) for supported values. Keys must be hashable.
    /// If the method throws, the dictionary will not be written at all so you can safely recover from the error.
    /// - Parameter dictionaryValue: Dictionary of type [AnyHashable: Any?], where the value must be a packable type.
    ///                              MessagePackFlatValue is not supported.
    /// - Throws: throws MessagePackWriterError.dictionaryTooBig if the dictionary has more than 2^32-1 key/value pairs.
    ///           throws MessagePackWriterError.unsupportedType if the dictionary contains an unpackable key or value.
    mutating func pack(_ dictionaryValue: [AnyHashable: Any?]) throws {
        try packDictionaryHeader(count: dictionaryValue.count)

        // Use another writer so we don't write anything until we're sure the map only has supported values,
        // allowing us to throw without destroying the payload.
        var mapWriter = MessagePackWriter()
        for (key, value) in dictionaryValue {
            try mapWriter.packAny(key)
            try mapWriter.packAny(value)
        }
        _data.append(mapWriter.data)
    }

    /// Pack Any value.
    /// - Parameter anyValue: value to pack. Must be one of the following types:
    ///                        Nil,
    ///                        Bool,
    ///                        UInt/UInt8/16/32/64,
    ///                        Int/Int8/16/32/64,
    ///                        Float/Double (and their aliases Float32 & Float64),
    ///                        String,
    ///                        Data,
    ///                        [Any?],
    ///                        [AnyHashable: Any?]
    /// - Throws: throws MessagePackWriterError.unsupportedType for unpackable types
    mutating func packAny(_ anyValue: Any?) throws {
        guard let anyValue = anyValue else {
            packNil()
            return
        }

        // I could not think of a better way to pack any than just a ton of if let, so here.we.go.
        switch anyValue {
            case let val as Bool: pack(val)

            // Numerics
            case let val as UInt: pack(val)
            case let val as UInt8: pack(val)
            case let val as UInt16: pack(val)
            case let val as UInt32: pack(val)
            case let val as UInt64: pack(val)
            case let val as Int: pack(val)
            case let val as Int8: pack(val)
            case let val as Int16: pack(val)
            case let val as Int32: pack(val)
            case let val as Int64: pack(val)
            case let val as Float: pack(val) // Also works for Float32
            case let val as Double: pack(val) // Also works for Float64

            case let val as String: try pack(val)
            case let val as Data: try pack(val)
            case let val as [Any?]: try pack(val)
            case let val as [AnyHashable: Any?]: try pack(val)

            default: throw MessagePackWriterError.unsupportedType(type: String(describing: type(of: anyValue)))
        }
    }

    /// Unsafely pack raw data.
    /// This method doesn't do any checks: it just appends raw data to the buffer.
    /// Use this to copy already packed data, or data you manually packed, useful
    /// if the library doesn't support something you need.
    /// - Parameter data: data to append to the current message
    mutating func unsafePackRawData(_ rawData: Data) {
        _data.append(rawData)
    }
}
