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

/// Delegate for `NetWatcher` class.
public protocol NetWatcherDelegate: AnyObject {
    
    /// Called when a new network event is captured.
    ///
    /// - Parameters:
    ///   - watcher: watcher singleton.
    ///   - event: event captured.
    func netWatcher(_ watcher: NetWatcher, didCaptureEvent event: NetworkEvent)
    
    /// Called when a request is ignored because it's in `ignoredHosts` list or
    /// `netWatcher(_:shouldRecordRequest:)` returned `false`.
    ///
    /// - Parameters:
    ///   - watcher: watcher singleton.
    ///   - request: request ignored.
    func netWatcher(_ watcher: NetWatcher, didIgnoreRequest request: URLRequest)
    
    /// Used to allow recording or ignore a particular request.
    /// When not implemented it always return `true`.
    ///
    /// NOTE: Keep in mind you can also use `ignoredHosts` to ignore host domains at the source.
    ///
    /// - Parameters:
    ///   - watcher: watcher singleton.
    ///   - request: received request.
    /// - Returns: Bool
    func netWatcher(_ watcher: NetWatcher, shouldRecordRequest request: URLRequest) -> Bool

}

extension NetWatcherDelegate {
    
    func netWatcher(_ watcher: NetWatcher, shouldRecordRequest request: URLRequest) -> Bool {
        true
    }

}
