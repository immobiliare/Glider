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

public class Log {
    
    public let configuration: Configuration
    
    public init(_ builder: ((inout Configuration) -> Void)) {
        var config = Configuration()
        builder(&config)
        self.configuration = config
    }
    
}
