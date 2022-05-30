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

public class SQLiteTransport: Transport {

    // MARK: - Public Properties
    
    /// Dispatch queue.
    public var queue: DispatchQueue?
    
    /// Delegate.
    public weak var delegate: SQLiteTransportDelegate?
    
    // MARK: - Private Properties



    // MARK: - Initialization
    
    public init(location: SQLiteDatabase.Location,
                bufferSize: Int = 100,
                flushInterval: TimeInterval? = nil) {
        
    }
    
    // MARK: - Conformance
    
    public func record(event: Event) -> Bool {
        true
    }

   
    
    
}
