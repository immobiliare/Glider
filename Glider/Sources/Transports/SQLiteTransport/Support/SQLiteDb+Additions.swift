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

#if os(Linux)
import CSQLite
#else
import SQLite3
#endif


extension SQLiteDb {
    
    // MARK: WAL
    
    /// Set WAL checkpoint mode.
    ///
    /// - Parameter mode: mode to set.
    public func walCheckpoint(mode: CheckpointMode = .passive) throws {
        try check(sqlite3_wal_checkpoint_v2(handle, nil, mode.flag, nil, nil))
    }
    
    // MARK: - User Schema Version

    /// Set the user version of database.
    ///
    /// - Parameters:
    ///   - version: version to set.
    ///   - schema: optional schema.
    public func setUserVersion(_ version: Int, schema: String? = nil) throws {
        let sql: String
        sql = schemaStatement(template: "PRAGMA %@user_version = \(version)", schema: schema)
        try exec(sql)
    }
    
    /// Get version integer value
    /// - Parameters:
    ///   - version: Version type (`user`, by default)
    ///   - schema: Optional schema
    /// - Throws: DatabaseError
    /// - Returns: Version integer value
    public func getVersion(_ version: Version, schema: String? = nil) throws -> Int {
        let sql:String
        sql = schemaStatement(template: "PRAGMA %@\(version.rawValue)", schema: schema)
        let stmt = try statement(sql: sql)
        guard try stmt.step() else {
            throw DatabaseError(reason: "Error fetching version",code:-1)
        }
        return stmt.integer(column: 0)!
    }
    
    // MARK: - Foreign Keys

    /// Has the database support for foreign keys.
    ///
    /// - Returns: Bool
    public func hasForeignKeys() throws -> Bool {
        let sql:String
        sql = schemaStatement(template: "PRAGMA foreign_keys;", schema: nil)
        let stmt = try statement(sql: sql)
        guard try stmt.step() else {
            throw DatabaseError(reason: "Error fetching version",code:-1)
        }
        return stmt.integer(column: 0) == 1
    }
    
    /// Enable or disable foreign keys if database supports it.
    ///
    /// - Parameters:
    ///   - enabled: enable or disable
    ///   - schema: optional schema.
    public func setForeignKeys(enabled: Bool, schema: String? = nil) throws {
        let sql: String
        sql = schemaStatement(template: "PRAGMA foreign_keys = \(enabled ? "ON" : "OFF")", schema: schema)
        try exec(sql)
    }
    
    // MARK: - Vacuum
    
    /// Set auto vacuum mode.
    ///
    /// - Parameters:
    ///   - autoVacuum: Auto vacuum mode-
    ///   - schema: Optional schema.
    public func set(autoVacuum: AutoVacuum, schema: String? = nil) throws {
        let sql = schemaStatement(template: "PRAGMA %@auto_vacuum = \(autoVacuum.rawValue)", schema: schema)
        try exec(sql)
    }
    
    /// Get current auto vacuum mode.
    ///
    /// - Parameter schema: Optional schema
    /// - Returns: `AutoVacuum`
    public func autoVacuum(schema: String? = nil) throws -> AutoVacuum {
        let sql = schemaStatement(template: "PRAGMA %@auto_vacuum", schema: schema)
        let stmt = try statement(sql: sql)
        guard try stmt.step() else {
            throw DatabaseError(reason: "Error fetching auto vacuum, step failed", code: -1)
        }
        return AutoVacuum(rawValue: stmt.integer(column: 0) ?? 0) ?? .none
    }
    
    /// The incremental_vacuum pragma causes up to N pages to be removed from the freelist.
    /// The database file is truncated by the same amount. The incremental_vacuum pragma has
    /// no effect if the database is not in auto_vacuum=incremental mode or if there are no pages on the freelist.
    /// If there are fewer than N pages on the freelist, or if N is less than 1, or if the "(N)" argument is omitted,
    /// then the entire freelist is cleared.
    ///
    /// - Parameters:
    ///   - pages: Number of pages to remove, 0 or nil will clear the entire free list
    ///   - schema: Optional schema
    public func incrementalVacuum(pages: Int? = nil, schema: String? = nil) throws {
        let sql: String
        if let pages = pages {
            sql = schemaStatement(template: "PRAGMA %@incremental_vacuum(\(pages))", schema: schema)
        } else {
            sql = schemaStatement(template: "PRAGMA %@incremental_vacuum", schema: schema)
        }
        try exec(sql)
    }
    
    /// Manually vacuum the database.
    ///
    /// It's important to keep your room neat and tidy! vacuum from time to time to reclaim unused pages,
    /// caused by deletes, this call vacuums some pages that cannot be reclaimed with auto vacuum.
    ///
    /// - Parameters:
    ///   - schema: Optional schema
    ///   - into: Optional new database path, if provided, a new vacuumed database will be created in the provided path
    public func vacuum(schema: String? = nil, into: String? = nil) throws {
        let sql: String
        if let into = into {
            let into_escaped = into.replacingOccurrences(of: "'", with: "''")
            sql = schemaStatement(template: "VACUUM %@ INTO '\(into_escaped)'", schema: schema)
        } else {
            sql = schemaStatement(template: "VACUUM %@", schema: schema)
        }
        try exec(sql)
    }
    
}
