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

/// This formatter is used to produce a log in standard RFC5424.
/// <https://datatracker.ietf.org/doc/html/rfc5424>
/// The message is composed of three parts: the header, the structured data part and the named message.
///
/// - header (priority, version, timestamp, host, application, pid, message id)
/// - structured data - section with square brackets
/// - message
///
/// `<priority>VERSION ISOTIMESTAMP HOSTNAME APPLICATION PID MESSAGEID [STRUCTURED-DATA] MESSAGE`
///
/// NOTE:
/// SysLog formatter does not log `LogScope`.
public class SysLogFormatter: FieldsFormatter {

    // MARK: - Private Properties
    
    private static let defaultHostname = "\(GliderSDK.identifier);\(GliderSDK.version)"

    /// Structured extra fields to get.
    private var extraFields: [FieldsFormatter.Field]
    
    /// Hostname.
    private var hostname: String
    
    // MARK: - Initialization
    
    /// Initialize a new syslog formatter.
    ///
    /// - Parameters:
    ///   - hostname: hostname of the machine. By default is used the SDK identifier + SDK version.
    ///   - extraFields: extra fields to attach to structured part of the log. By default `.subsystem` and `.category` are used.
    public init(hostname: String? = nil,
                extraFields: [FieldsFormatter.Field] = [.subsystem(), .category()]) {
        self.hostname = hostname ?? Self.defaultHostname
        self.extraFields = extraFields
        
        super.init(fields: [])
    }
    
    // MARK: - Conformance
    
    public override func format(event: Event) -> SerializableData? {
        let payload = SysLogPayload(event: event, hostname: hostname, extraFields: extraFields)
        return payload.formatted()
    }
    
}
