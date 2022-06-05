//
//  File.swift
//  
//
//  Created by Daniele Margutti on 30/05/22.
//

import Foundation

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
