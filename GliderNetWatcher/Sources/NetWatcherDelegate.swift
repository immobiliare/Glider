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

/// Delegate for net watcher events.
public protocol NetWatcherDelegate: AnyObject {
    
    /// Called when a new network event is captured.
    ///
    /// - Parameters:
    ///   - watcher: watcher singleton.
    ///   - event: event captured.
    func netWatcher(_ watcher: NetWatcher, didCaptureEvent event: NetworkEvent)
    
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
