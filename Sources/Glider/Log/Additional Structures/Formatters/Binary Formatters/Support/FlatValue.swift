import Foundation

/// MessagePackFlatValue represents a raw partial messagepack message
/// which can be one or many messagepack objects
/// This struct is mainly useful to pack/unpack arrays of complex values
/// where the array count does not strictly match the number of messagepack
/// values.
/// Note: this struct assumes that you know what you're doing,
/// and will not refuse to pack invalid or empty data.
public struct MessagePackFlatValue {
    public let data: Data

    /// Init with MessagePack data
    init(from: Data) {
        data = from
    }

    /// Init with a writer closure
    /// Example:
    /// ```
    /// let value = MessagePackFlatValue {
    ///     $0.pack(2)
    ///     $0.pack("foo")
    /// }
    /// ```
    init(from closure: (inout MessagePackWriter) throws -> Void) rethrows {
        var writer = MessagePackWriter()
        try closure(&writer)
        data = writer.data
    }
}

extension MessagePackWriter {
    public var flatValue: MessagePackFlatValue {
        MessagePackFlatValue(from: data)
    }
}
