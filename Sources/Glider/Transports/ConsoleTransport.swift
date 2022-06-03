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

/// `ConsoleTransport` is used to print log directly on Xcode or other IDE console.
public class ConsoleTransport: Transport {
    
    // MARK: - Public Properties
    
    public var queue: DispatchQueue? = nil
    
    /// Formatter used to transform a payload into a string.
    public let formatters: [EventFormatter]
    
    // MARK: - Initialization
    
    /// Initialize new console transport.
    ///
    /// - Parameters:
    ///   - formatters: formatters to use.
    ///   - queue: queue to use, `nil` create a new queue by default.
    public init(formatters: [EventFormatter] = [FieldsFormatter.default()],
                queue: DispatchQueue? = nil) {
        self.formatters = formatters
        self.queue = queue ?? DispatchQueue(label: String(describing: type(of: self)))
    }
    
    // MARK: - Public Functions
    
    public func record(event: Event) -> Bool {
        guard let message = formatters.format(event: event)?.asString(),
              message.isEmpty == false else {
            return false
        }
        
        print(message)
        return true
    }
    
}
