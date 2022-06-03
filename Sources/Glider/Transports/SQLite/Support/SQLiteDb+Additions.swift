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

extension SQLiteDb {
    
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
    
}
