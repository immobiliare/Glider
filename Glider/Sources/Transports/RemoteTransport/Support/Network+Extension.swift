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
#if canImport(Network)
import Network

// MARK: - NWBrowser.Result

extension NWBrowser.Result {
    
    internal var name: String? {
        guard case .service(let name, _, _, _) = endpoint else {
            return nil
        }
        return name
    }
    
}

// MARK: - Helpers (Binary Protocol)

// Expects big endian.

internal extension Data {
    
    init(_ value: UInt32) {
        var contentSize = value.bigEndian
        self.init(bytes: &contentSize, count: MemoryLayout<UInt32>.size)
    }

    func from(_ from: Data.Index, size: Int) -> Data {
        self[(from + startIndex)..<(from + size + startIndex)]
    }
    
}

internal extension UInt32 {
    
    init(_ data: Data) {
        self = UInt32(data.parseInt(size: 4))
    }
    
}

fileprivate extension Data {
    
    func parseInt(size: Int) -> UInt64 {
        precondition(size > 0 && size <= 8)
        var accumulator: UInt64 = 0
        // swiftlint:disable identifier_name
        for i in 0..<size {
            let shift = (size - i - 1) * 8
            accumulator |= UInt64(self[self.startIndex + i]) << UInt64(shift)
        }
        return accumulator
    }
    
}

// MARK: - NWListener.State

extension NWListener.State {
    
    public var description: String {
        switch self {
        case .setup:
            return ".setup"
        case .waiting(let error):
            return ".waiting(error: \(error))"
        case .ready:
            return ".ready"
        case .failed(let error):
            return ".failed(error: \(error))"
        case .cancelled:
            return ".cancelled"
        @unknown default:
            return ".unknown"
        }
    }
    
}

#endif
