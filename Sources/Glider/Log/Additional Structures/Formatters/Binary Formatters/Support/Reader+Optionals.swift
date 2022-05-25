import Foundation

// MARK: Public API - Strongly typed optional readers

public extension MessagePackReader {
    /// Read a boolean.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Returns: The unpacked value or nil
    /// - Throws: MessagePackReaderError if the value could not be unpacked
    mutating func read(_: Bool?.Type) throws -> Bool? {
        if try tryConsumeNil() { return nil }
        return try read(Bool.self)
    }

    /// Read a Int8.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Returns: The unpacked value or nil
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: Int8?.Type) throws -> Int8? {
        if try tryConsumeNil() { return nil }
        return try read(Int8.self)
    }

    /// Read a Int16.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Returns: The unpacked value or nil
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: Int16?.Type) throws -> Int16? {
        if try tryConsumeNil() { return nil }
        return try read(Int16.self)
    }

    /// Read a Int32.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Returns: The unpacked value or nil
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: Int32?.Type) throws -> Int32? {
        if try tryConsumeNil() { return nil }
        return try read(Int32.self)
    }

    /// Read a Int64.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Returns: The unpacked value or nil
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: Int64?.Type) throws -> Int64? {
        if try tryConsumeNil() { return nil }
        return try read(Int64.self)
    }

    /// Read a Int.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Returns: The unpacked value or nil
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: Int?.Type) throws -> Int? {
        if try tryConsumeNil() { return nil }
        return try read(Int.self)
    }

    /// Read a UInt8.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Returns: The unpacked value or nil
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: UInt8?.Type) throws -> UInt8? {
        if try tryConsumeNil() { return nil }
        return try read(UInt8.self)
    }

    /// Read a UInt16.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Returns: The unpacked value or nil
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: UInt16?.Type) throws -> UInt16? {
        if try tryConsumeNil() { return nil }
        return try read(UInt16.self)
    }

    /// Read a UInt32.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Returns: The unpacked value or nil
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: UInt32?.Type) throws -> UInt32? {
        if try tryConsumeNil() { return nil }
        return try read(UInt32.self)
    }

    /// Read a UInt64.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Returns: The unpacked value or nil
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: UInt64?.Type) throws -> UInt64? {
        if try tryConsumeNil() { return nil }
        return try read(UInt64.self)
    }

    /// Read a UInt.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Returns: The unpacked value or nil
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number didn't fit in the container.
    mutating func read(_: UInt?.Type) throws -> UInt? {
        if try tryConsumeNil() { return nil }
        return try read(UInt.self)
    }

    /// Read a Float/Float32.
    /// A packed Double value is not unpackable and will throw an error.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Returns: The unpacked value or nil
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.containerTooSmall if the number wasn't a float.
    mutating func read(_: Float?.Type) throws -> Float? {
        if try tryConsumeNil() { return nil }
        return try read(Float.self)
    }

    /// Read a Double/Float64.
    /// A packed Float value will be converted into a Double.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Returns: The unpacked value or nil
    /// - Throws: MessagePackReaderError if the value could not be unpacked
    mutating func read(_: Double?.Type) throws -> Double? {
        if try tryConsumeNil() { return nil }
        return try read(Double.self)
    }

    /// Read a String.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Returns: The unpacked value or nil
    /// - Throws: MessagePackReaderError if the value could not be unpacked
    mutating func read(_: String?.Type) throws -> String? {
        if try tryConsumeNil() { return nil }
        return try read(String.self)
    }

    /// Read a Data.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Returns: The unpacked value or nil
    /// - Throws: MessagePackReaderError if the value could not be unpacked
    mutating func read(_: Data?.Type) throws -> Data? {
        if try tryConsumeNil() { return nil }
        return try read(Data.self)
    }

    /// Read a dictionary.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Throws: MessagePackReaderError if the value could not be unpacked,
    ///           MessagePackReaderError.unhashableKey if a key isn't AnyHashable.
    mutating func readOptionalDictionary() throws -> [AnyHashable: Any?]? {
        if try tryConsumeNil() { return nil }
        return try readDictionary()
    }

    /// Read a dictionary by mapping the values to a complex object manually.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Parameter mapClosure: The closure that will be ran to map the flat values to
    ///                         a key/object.
    /// - Throws: MessagePackReaderError if the value could not be unpacked
    mutating func readAndMapOptionalDictionary<T>(_ mapClosure: (inout MessagePackReader) throws -> (AnyHashable, T)) throws -> [AnyHashable: T]? {
        // swiftlint:disable:previous line_length
        if try tryConsumeNil() { return nil }
        return try readAndMapDictionary(mapClosure)
    }

    /// Read an array's header and return its length. Does not attempt to read the array.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Throws: MessagePackReaderError if the value could not be unpacked
    mutating func readOptionalArrayHeader() throws -> UInt? {
        if try tryConsumeNil() { return nil }
        return try readArrayHeader()
    }

    /// Read an array.
    /// Does not return nil for a bad type, but only if nil
    /// was packed. Use `try?` for this use case.
    /// - Throws: MessagePackReaderError if the value could not be unpacked
    mutating func readOptionalArray() throws -> [Any?]? {
        if try tryConsumeNil() { return nil }
        return try readArray()
    }

    /// Read an array by mapping the values to a complex object manually.
    /// - Parameter mapClosure: The closure that will be ran to map the flat values to
    ///                         an object.
    /// - Throws: MessagePackReaderError if the value could not be unpacked
    mutating func readAndMapOptionalArray<T>(_ mapClosure: (inout MessagePackReader) throws -> T) throws -> [T]? {
        if try tryConsumeNil() { return nil }
        return try readAndMapArray(mapClosure)
    }
}
