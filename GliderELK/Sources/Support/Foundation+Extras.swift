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
