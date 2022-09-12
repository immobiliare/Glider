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
import NIO

extension FixedWidthInteger {
    
    /// From: Swift NIO `ByteBuffer-int.swift` (can't be used since internal protection level)
    /// Returns the next power of two.
    @inlinable
    internal func nextPowerOf2() -> Self {
        guard self != 0 else {
            return 1
        }
        return 1 << (Self.bitWidth - (self - 1).leadingZeroBitCount)
    }
    
}

extension TimeAmount {
    /// Provides access to the time amount in the seconds unit
    var rawSeconds: Double {
        Double(self.nanoseconds) / Double(1_000_000_000)
    }
}
