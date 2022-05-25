import Foundation

// MARK: Public API - Optional extensions

public extension MessagePackWriter {
    /// Pack an optional boolean value.
    /// - Parameter value: Boolean value
    mutating func packOptional(_ value: Bool?) {
        guard let value = value else { packNil(); return }
        pack(value)
    }

    /// Pack an optional integer.
    /// This method will automatically use the most compact way to pack the value.
    /// Prefer this method to pack(int8:) pack(int16:) etc.
    /// For 32 bit platforms, pack(int64:) might be useful.
    /// - Parameter value: Integer value
    mutating func packOptional<T: BinaryInteger>(_ value: T?) {
        guard let value = value else { packNil(); return }
        pack(value)
    }

    /// Pack a double. Also known as float64.
    /// This method will automatically use the most compact way to pack the value.
    /// - Parameter value: Double/Float64 value
    mutating func packOptional(_ value: Double?) {
        guard let value = value else { packNil(); return }
        pack(value)
    }

    /// Pack a double. Also known as float32.
    /// This method will automatically use the most compact way to pack the value.
    /// - Parameter value: Float/Float32 value
    mutating func packOptional(_ value: Float?) {
        guard let value = value else { packNil(); return }
        pack(value)
    }

    /// Pack an optional String.
    /// - Parameter value: String value
    /// - Throws: throws MessagePackWriterError.stringTooBig if the
    ///           utf-8 representation of the string is longer than 2^32-1 bytes.
    mutating func pack(_ value: String?) throws {
        guard let value = value else { packNil(); return }
        try pack(value)
    }

    /// Pack an optional Data stuct.
    /// - Parameter value: Data value
    /// - Throws: throws MessagePackWriterError.dataTooBig if the data is bigger than 2^32-1 bytes.
    mutating func pack(_ value: Data?) throws {
        guard let value = value else { packNil(); return }
        try pack(value)
    }

    /// Pack an optional flat array.
    /// A flat array is an array where the count doesn't exactly match the MessagePack
    /// objects, but rather the number of complex MessagePack objects, which
    /// might be made of multiple consecutive primitive objects.
    ///
    /// Note: No checks are made on the packed values, they will be packed as-is.
    ///
    /// It must be composed of MessagePackFlatValue.
    /// - Parameter value: Array of MessagePackFlatValue to pack
    /// - Throws: throws MessagePackWriterError.arrayTooBig if the array is longer than 2^32-1 elements
    mutating func packOptionalFlatArray(_ array: [MessagePackFlatValue]?) throws {
        guard let array = array else { packNil(); return }
        try packFlatArray(array)
    }

    /// Pack an optional array.
    /// See pack(_: Any?) for supported values. MessagePackFlatValue is not supported here.
    /// If the method throws, the array will not be written at all so you can safely recover from the error.
    /// - Parameter value: Array of Any?, where Any must be a packable type.
    /// - Throws: throws MessagePackWriterError.arrayTooBig if the array is longer than 2^32-1 elements.
    ///           throws MessagePackWriterError.unsupportedType if the array contains an unpackable value.
    mutating func pack(_ value: [Any?]?) throws {
        guard let value = value else { packNil(); return }
        try pack(value)
    }

    /// Pack an optional flat array.
    /// A flat array is an array where the count doesn't exactly match the MessagePack
    /// objects, but rather the number of complex MessagePack objects, which
    /// might be made of multiple consecutive primitive objects.
    ///
    /// Note: No checks are made on the packed values, they will be packed as-is.
    ///
    /// It must be composed of MessagePackFlatValue.
    /// - Parameter value: Array of MessagePackFlatValue to pack
    /// - Throws: throws MessagePackWriterError.arrayTooBig if the array is longer than 2^32-1 elements
    mutating func packOptionalFlatDictionary(_ dictionary: [AnyHashable: MessagePackFlatValue]?) throws {
        guard let dictionary = dictionary else { packNil(); return }
        try packFlatDictionary(dictionary)
    }

    /// Pack an optional dictionary.
    /// See pack(_: Any?) for supported values. Keys must be hashable.
    /// If the method throws, the dictionary will not be written at all so you can safely recover from the error.
    /// - Parameter dictionaryValue: Dictionary of type [AnyHashable: Any?], where the value must be a packable type.
    ///                              MessagePackFlatValue is not supported.
    /// - Throws: throws MessagePackWriterError.dictionaryTooBig if the dictionary has more than 2^32-1 key/value pairs.
    ///           throws MessagePackWriterError.unsupportedType if the dictionary contains an unpackable key or value.
    mutating func pack(_ dictionaryValue: [AnyHashable: Any?]?) throws {
        guard let dictionaryValue = dictionaryValue else { packNil(); return }
        try pack(dictionaryValue)
    }
}
