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

public class XCodeLogFormatter: FieldsFormatter {
    
    // MARK: - Public Properties
    
    /// If `true`, the source file and line indicating
    /// the call site of the log request will be added to formatted log messages.
    public let showCallSite: Bool
    
    // MARK: - Initialization
    
    /// Initialize a new formatter which is ideal for use within Xcode.
    /// This format is not well-suited for parsing.
    ///
    /// - Parameter showCallSite: If `true`, the source file and line indicating
    ///                           the call site of the log request will be added to formatted log messages.
    public init(showCallSite: Bool = true) {
        var fields: [FieldsFormatter.Field] = [
            .timestamp(style: .iso8601),
            .delimiter(style: .spacedPipe),
            .level(style: .short, {
                $0.padding = .right(columns: 4)
            }),
            .delimiter(style: .custom(": ")),
            .message()
        ]
        
        if showCallSite {
            fields.append(contentsOf: [
                .literal(" ("),
                .callSite(),
                .literal(") "),
            ])
        }
        
        self.showCallSite = showCallSite
        
        super.init(fields: fields)
    }
    
    @available(*, unavailable)
    public override init(fields: [FieldsFormatter.Field]) {
        fatalError("Use init(options:) for JSONFormatter")
    }
    
}
