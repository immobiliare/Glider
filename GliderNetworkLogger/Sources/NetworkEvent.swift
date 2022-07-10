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
import Glider

public struct NetworkEvent: SerializableObject {
    
    public func serializeMetadata() -> Metadata? {
        nil
    }
    
    public func serialize(with strategies: SerializationStrategies) -> Data? {
        nil
    }
    
}
