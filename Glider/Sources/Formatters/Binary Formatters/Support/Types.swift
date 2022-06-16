import Foundation
@usableFromInline internal typealias Byte = UInt8

/// MessagePackType defines the header to write.
/// Since some values are inlined in the header, this enum isn't RawRepresentable directly
/// This also handles headers that need an additional value, like a size
/// Only values that are inlined or need a size to be defined are passed as argument
@usableFromInline
enum MessagePackType {
    case `nil`
    case boolean(_ value: Bool)

    // Integers
    case positiveFixedInt(_ value: UInt8)
    case negativeFixedInt(_ value: Int8)
    case int8
    case int16
    case int32
    case int64
    case uint8
    case uint16
    case uint32
    case uint64

    // Floats
    case float32
    case float64 // Also known as double!

    // Strings
    case fixedStr(size: UInt8)
    case str8
    case str16
    case str32

    // Binary
    case bin8
    case bin16
    case bin32

    // Arrays
    case fixedArray(size: UInt8)
    case array16
    case array32

    // Maps
    case fixedMap(size: UInt8)
    case map16
    case map32

    // Extension - TODO
}

// Convinence extensions that allow checking if a type is of a general type
extension MessagePackType {
    func isArray() -> Bool {
        switch self {
            case .fixedArray, .array16, .array32:
                return true
            default:
                return false
        }
    }

    func isMap() -> Bool {
        switch self {
            case .fixedMap, .map16, .map32:
                return true
            default:
                return false
        }
    }

    func isSignedInteger() -> Bool {
        switch self {
            case .positiveFixedInt, .negativeFixedInt, .int8, .int16, .int32, .int64:
                return true
            default:
                return false
        }
    }

    func isUnsignedInteger() -> Bool {
        switch self {
            case .positiveFixedInt, .uint8, .uint16, .uint32, .uint64:
                return true
            default:
                return false
        }
    }

    func isFloat() -> Bool {
        switch self {
            case .float32, .float64:
                return true
            default:
                return false
        }
    }

    func isString() -> Bool {
        switch self {
            case .str8, .str16, .str32:
                return true
            default:
                return false
        }
    }

    func isBinary() -> Bool {
        switch self {
            case .bin8, .bin16, .bin32:
                return true
            default:
                return false
        }
    }
}

// Serialization extension
internal extension MessagePackType {
    @usableFromInline
    var headerValue: Byte {
        switch self {
            case .nil: return 0xC0
            case let .boolean(value): return value ? 0xC3 : 0xC2

            // Integers
            // posfixint: 0x7f (0111_1111) is the maximum value and can be used to mask a 8bit integer
            case let .positiveFixedInt(value): return Byte(value & 0x7F)
            // negfixint: 111xxxxx, 5 bit negative integer. 1f is the opposite of e0
            case let .negativeFixedInt(value): return Byte(0xE0 + (0x1F & UInt8(truncatingIfNeeded: value)))
            case .int8: return 0xD0
            case .int16: return 0xD1
            case .int32: return 0xD2
            case .int64: return 0xD3
            case .uint8: return 0xCC
            case .uint16: return 0xCD
            case .uint32: return 0xCE
            case .uint64: return 0xCF

            // Floats
            case .float32: return 0xCA
            case .float64: return 0xCB

            // Strings
            // 5 bit integer. It is up to the code calling this to check that the size fits in a fixedStr
            case let .fixedStr(value): return Byte(0xA0 + (0x1F & value))
            case .str8: return 0xD9
            case .str16: return 0xDA
            case .str32: return 0xDB

            // Binary
            case .bin8: return 0xC4
            case .bin16: return 0xC5
            case .bin32: return 0xC6

            // Arrays
            // fixed ararys encode their size on 4 bits, hide the rest using 00001111
            case let .fixedArray(size): return Byte(0x90 + size & 0xF)
            case .array16: return 0xDC
            case .array32: return 0xDD

            // Maps
            case let .fixedMap(size): return Byte(0x80 + size & 0xF) // same as fixed arrays
            case .map16: return 0xDE
            case .map32: return 0xDF
        }
    }
}

// Deserialization extension
internal extension MessagePackType {
    static func from(_ byte: Byte) throws -> MessagePackType {
        switch byte {
            case 0xC0: return .nil
            case 0xC3: return .boolean(true)
            case 0xC2: return .boolean(false)

            case 0x00 ... 0x7F: return .positiveFixedInt(byte)
            case 0xE0 ... 0xFF: return .negativeFixedInt(Int8(bitPattern: byte))
            case 0xD0: return .int8
            case 0xD1: return .int16
            case 0xD2: return .int32
            case 0xD3: return .int64
            case 0xCC: return .uint8
            case 0xCD: return .uint16
            case 0xCE: return .uint32
            case 0xCF: return .uint64

            case 0xCA: return .float32
            case 0xCB: return .float64

            case 0xA0 ... 0xBF: return .fixedStr(size: byte - 0xA0)
            case 0xD9: return .str8
            case 0xDA: return .str16
            case 0xDB: return .str32

            case 0xC4: return .bin8
            case 0xC5: return .bin16
            case 0xC6: return .bin32

            case 0x90 ... 0x9F: return .fixedArray(size: byte - 0x90)
            case 0xDC: return .array16
            case 0xDD: return .array32

            case 0x80 ... 0x8F: return .fixedMap(size: byte - 0x80)
            case 0xDE: return .map16
            case 0xDF: return .map32

            default:
                throw MessagePackReaderError.unknownType(rawByte: byte)
        }
    }
}

// Extension for easy debug printing
extension MessagePackType: CustomStringConvertible {
    @usableFromInline
    var description: String {
        let baseDesc: String = { switch self {
            case let .boolean(value): return "boolean (\(value ? "true" : "false"))"
            case let .positiveFixedInt(value): return "positive fixed int (\(value))"
            case let .negativeFixedInt(value): return "negative fixed int (\(value))"
            case let .fixedArray(size): return "fixed array (\(size))"
            case let .fixedMap(size): return "fixed map (\(size))"
            case let .fixedStr(size): return "fixed str (\(size))"
            default: return String(describing: self)
        } }()
        return baseDesc + String(format: "%02X", headerValue)
    }
}
