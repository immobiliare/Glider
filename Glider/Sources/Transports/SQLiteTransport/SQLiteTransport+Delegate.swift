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

/// The delegate used to receive notifications from a `SQLiteTransport` service.
public protocol SQLiteTransportDelegate: AnyObject {
    
    /// A new database connection was opened.
    func sqliteTransport(_ transport: SQLiteTransport, openedDatabaseAtURL location: SQLiteDb.Location, isFileExist: Bool)
    
    /// An error has occurred while executing an sqlite query with the underlying storage.
    func sqliteTransport(_ transport: SQLiteTransport, didFailQueryWithError error: Error)
    
    /// A set of payloads were written inside the database.
    func sqliteTransport(_ transport: SQLiteTransport, writtenPayloads: [ThrottledTransport.Payload])
    
    /// Called when database schema was updated to a newer version.`
    func sqliteTransport(_ transport: SQLiteTransport, schemaMigratedFromVersion oldVersion: Int, toVersion newVersion: Int)

    /// Called when database is purged by old logs.
    func sqliteTransport(_ transport: SQLiteTransport, purgedLogs count: Int64)

}
