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

#if canImport(Logging)
import Foundation
import Logging
import Glider

/// The `GliderSwiftLogHandler` is just a `LogHandler` object which you can assign to the
/// swift-log settings to use `Glider` as backend library.
///
/// Example
///
/// ```swift
/// LoggingSystem.bootstrap {
///     var handler = GliderSwiftLogHandler(label: $0, logger: gliderLog)
///     handler.logLevel = .trace
///     return handler
/// }
/// ```
///
/// See the unit test suite for a complete example.
public struct GliderSwiftLogHandler: LogHandler {
    
    // MARK: - Public Properties
    
    /// Level.
    public var logLevel: Logger.Level = .info
    
    /// Metadata used as scope's `extra` dictionary in Glider.
    public var metadata: Logger.Metadata {
        get {
            GliderSDK.shared.scope.extra.values.compactMapValues({
                guard let string = $0?.asString() else {
                    return nil
                }
                
                return .string(string)
            })
        }
        set {
            GliderSDK.shared.scope.extra = newValue.asGliderMetadata()
        }
    }
        
    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get {
            return metadata[key]
        }
        set(newValue) {
            if let newValue = newValue {
                GliderSDK.shared.scope.extra[key] = "\(newValue)"
            }
        }
    }
    
    // MARK: - Private Properties
    
    /// Label which describe the logger.
    private let label: String
    
    /// Backend glider logger.
    private var logger: Glider.Log

    // MARK: - Initialization
    
    /// Initialize a new backend logger for swift-log.
    ///
    /// - Parameters:
    ///   - label: label to assign.
    ///   - logger: logger glider instance.
    public init(label: String, logger: Glider.Log) {
        self.label = label
        self.logger = logger
    }
    
    // MARK: - Conformance to swift-log
    
    // swiftlint:disable function_parameter_count
    public func log(level: Logger.Level, message: Logger.Message,
                    metadata: Logger.Metadata?,
                    source: String, file: String, function: String, line: UInt) {
        logger[level.asGlider()]?.write({
            $0.message = "\(message, privacy: .public)"
            $0.tags = [
                "label": self.label,
                "source": source,
                "logger": "swiftlog"
            ]
            $0.extra = metadata?.asGliderMetadata()
        }, function: function, filePath: file, fileLine: Int(line))
    }
    
}

// MARK: - Logger.Level

extension Logger.Level {
    
    /// Map the swift-log logger severity levels to Glider's representation.
    ///
    /// - Returns: `Glider.Level`
    func asGlider() -> Glider.Level {
        switch self {
        case .trace: return .trace
        case .debug: return .debug
        case .info: return .info
        case .notice: return .notice
        case .warning: return .warning
        case .error: return .error
        case .critical: return .critical
        }
    }
    
}

// MARK: - Logger.Metadata

extension Logger.Metadata {
    
    /// Create a `Glider.Metadata` representation of the `Logger.Metadata` object.
    ///
    /// - Returns: `Glider.Metadata`
    func asGliderMetadata() -> Glider.Metadata {
        let dict: [String: SerializableData?] = self.mapValues {
            "\($0)"
        }
        return Glider.Metadata.init(dict)
    }
    
}

#endif
