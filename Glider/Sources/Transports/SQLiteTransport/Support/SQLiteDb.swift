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


public class SQLiteDb {
    
    // MARK: - Public Properties
    
    /// Returns the version string of the SQLite3 library that is used.
    public static var version: String? {
        guard let version = sqlite3_libversion() else {
            return nil
        }
        
        return String(cString: version)
    }
    
    /// Returns the version string of the SQLite3 library that is used.
    public static var versionNumber: Int {
      return Int(sqlite3_libversion_number())
    }
    
    /// The debug logger used to check the internal sqlite.
    public static var logger: Log?
    
    /// Use the JSON1 extension for JSON values, currently
    /// it means that codable will use JSONs as strings, and not data.
    public var useJSON1 = true
    
    /// JSONEncoder used when you need to encode `Codable` object.
    /// `useJSON1` must be present.
    public var jsonEncoder = JSONEncoder()
    
    /// JSONDecoder used to decode data encoded via `Codable`.
    /// `useJSON1` must be active.
    public var jsonDecoder = JSONDecoder()
    
    /// The `rowid` of the last row inserted.
    /// It returns -1 if no database handle is opened.
    public var lastRowId: Int64 {
        guard handle != nil else {
            return -1
        }
        
        return sqlite3_last_insert_rowid(handle)
    }
    
    /// The number of rows changed by the last `INSERT`, `UPDATE`, or `DELETE` statement.
    /// It returns -1 if no database handle is opened.
    public var lastChanges: Int {
        guard handle != nil else {
            return -1
        }
        
        return Int(sqlite3_changes(handle))
    }
    
    /// The number of rows changed via `INSERT`, `UPDATE`, or `DELETE` statements since the
    /// database was opened.
    /// It returns -1 if no database handle is opened.
    public var totalChanges: Int {
        guard handle != nil else {
            return -1
        }
        
        return Int(sqlite3_total_changes(handle))
    }

    // MARK: - Private Properties
    
    // See [here](https://stackoverflow.com/questions/26883131/sqlite-transient-undefined-in-swift).
    internal static let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
    internal static let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
    /// Internal handler to sqlite database connection.
    internal var handle: OpaquePointer?
    
    // MARK: - Initialization
    
    /// Initialize a new database at given location.
    ///
    /// - Parameters:
    ///   - location: location of the database.
    ///   - options: options.
    public init(_ location: Location, options: Options = .init()) throws {
        try open(location: location, options: options)
    }
    
    // MARK: - Public Functions
    
    /// Set the busy timeout, useful for WAL mode.
    /// See [sqlite3_busy_timeout()](https://sqlite.org/c3ref/busy_timeout.html)
    ///
    /// - Parameter ms: milleseconds for timeout
    public func setBusyTimeout(_ ms: Int) throws {
        try check(sqlite3_busy_timeout(self.handle, Int32(ms)))
    }
    
    public func setWalCheckpoint(mode: CheckpointMode = .passive) throws {
        try check(sqlite3_wal_checkpoint_v2(handle, nil, mode.flag, nil, nil))
    }
    
    /// Set user version.
    ///
    /// - Parameters:
    ///   - version: Version numeric value
    ///   - schema: Optional schema
    public func setVersion(_ version:Int, schema:String? = nil) throws {
        let sql: String
        sql = schemaStatement(template: "PRAGMA %@user_version = \(version)", schema: schema)
        try exec(sql)
    }
    
    /// Get the last error from SQLite3.
    ///
    /// - Parameter extended: extended description, `false` by default.
    /// - Returns: `DatabaseError`
    public func lastError(extended: Bool = false) -> DatabaseError? {
        guard handle != nil else {
            return nil
        }
        
        let message = String(cString: sqlite3_errmsg(handle))
        let code = (extended ? sqlite3_extended_errcode(handle) : sqlite3_errcode(handle))
        guard code != 0 else {
            return nil
        }
        
        return DatabaseError(reason: message, code: code)
    }
    
    // MARK: - Query
    
    /// Execute an Update query statement.
    ///
    /// - Parameter SQL: SQL string.
    /// - Throws: throw an exception if something fails executing query.
    /// - Returns: Statement
    @discardableResult
    public func update(sql: String, bindTo values: [Any?]? = nil) throws -> Statement {
        let statement = try prepare(sql: sql)
        if let values = values {
            try statement.bind(values)
        }
        try statement.step()
        return statement
    }
    
    /// Compile a prepared statement.
    ///
    /// - Parameter sql: SQL statement to compile.
    /// - Throws: throw an exception if something fails.
    /// - Returns: SQLiteStatement
    public func prepare(sql: String) throws -> Statement {
        guard handle != nil else {
            throw DatabaseError(reason: "Database already closed", code: SQLITE_MISUSE)
        }
        
        return try Statement(database: self, sql: sql)
    }
    
    /// Execute a select query statement.
    ///
    /// - Parameters:
    ///   - SQL: SQL string.
    ///   - values: values to bind.
    /// - Throws: throw an exception if something fails executing query.
    /// - Returns: Statement
    public func select<T>(sql: String, bindTo values: [Any?]? = nil,
                       _ handler: ((_ columnCount: Int32, _ stmt: Statement) -> T?)) throws -> [T] {
        let statement = try prepare(sql: sql)
        if let values = values {
            try statement.bind(values)
        }
        try statement.step()
        return statement.iterateRows(handler)
    }
    
    /// Executes a BEGIN, calls the provided closure and executes a ROLLBACK if an exception occurs or a COMMIT if no exception occurs.
    ///
    /// - parameter closure: Block to be executed inside transaction
    /// - throws: ErrorType
    public func updateWithTransaction(_ closure: () throws -> ()) throws {
        try update(sql: "BEGIN")
        do {
            try closure()
            try update(sql: "COMMIT")
        } catch let e {
            try update(sql: "ROLLBACK")
            throw e
        }
    }
    
    /// Execute a select statement and bind values.
    ///
    /// - Parameters:
    ///   - SQL: sql query.
    ///   - values: binded values
    /// - Returns: Statement
    public func select(sql: String, bindTo values: [Any?]? = nil) throws -> Statement {
        let statement = try prepare(sql: sql)
        if let values = values {
            try statement.bind(values)
        }
        try statement.step()
        return statement
    }
    
    /// Execute a select query statement.
    ///
    /// - Parameters:
    ///   - SQL: SQL string.
    ///   - values: values to bind.
    /// - Throws: throw an exception if something fails executing query.
    /// - Returns: Statement.
    public func select<T>(SQL: String, bindTo values: [Any?]? = nil,
                       _ handler: ((_ columnCount: Int32, _ stmt: Statement) -> T?)) throws -> [T] {
        let statement = try prepare(sql: SQL)
        if let values = values {
            try statement.bind(values)
        }
        try statement.step()
        return statement.iterateRows(handler)
    }
    
    // MARK: - Private Functions
    
    /// It is not possible to use prepared statement parameters for the statement name
    ///
    /// - Parameters:
    ///   - template: A string format containing a single %@ sequence, to be replaced with the schema identifier if available
    ///   - schema: Optional schema name
    /// - Returns: An SQL statement with or without a schema
    internal func schemaStatement(template:String,schema:String?) -> String{
        let schema_prefix: String
        if let schema = schema {
            schema_prefix = schema.appending(".")
        } else {
            schema_prefix = ""
        }
        
        return String(format:template,schema_prefix)
    }
    
    /// Execute SQL statement.
    /// - Parameter sql: SQL statement string.
    public func exec(_ sql: String) throws {
        SQLiteDb.logger?.info?.write(msg: "Executing: \(sql)")
        
        try check(sqlite3_exec(handle, sql, nil, nil, nil))
    }
    
    /// A convenience utility to create a new statement.
    /// 
    /// - Parameter sql: SQL statement
    /// - Throws: DatabaseError
    /// - Returns: A new statement associated with this database connection
    public func statement<S: Statement>(sql:String) throws -> S {
        return try S(database: self, sql: sql)
    }
    
    /// Validate an operation result and throw error if it's failure.
    ///
    /// - Parameter rc: code received.
    internal func check(_ rc:Int32) throws {
        try type(of: self).check(rc, handle: handle)
    }
    
    /// Opens a new databae connection.
    /// NOTE: The old connection is closed if open.
    private func open(location: Location, options: Options) throws {
        close()
        var lhandle : OpaquePointer?
        let flags: Int32 = options.openMode.rawValue | options.threadMode.flag | options.cacheMode.flag | options.protection.flag
        let rc = sqlite3_open_v2(location.description,
                                 &lhandle,
                                 flags, nil)
        
        defer {
            if rc != SQLITE_OK , let handle = lhandle {
                sqlite3_close(handle)
            }
        }
        
        try SQLiteDb.check(rc,handle: lhandle)
        self.handle = lhandle
        
        SQLiteDb.logger?.debug?.write(msg: "Opened database: \(location.description)")
    }
    
    /// Close a database connection.
    public func close() {
        guard handle != nil else {
            return
        }
        
        sqlite3_close(handle)
        handle = nil
        
        SQLiteDb.logger?.debug?.write(msg: "Closed database")
    }
    
    deinit {
        close()
    }
    
    // MARK: - Static Functions
    
    internal static func check(_ rc:Int32, handle:OpaquePointer?) throws {
        guard rc == SQLITE_OK else {
            let reason:String
            if let handle = handle {
                reason = String(cString: sqlite3_errmsg(handle))
            } else {
                reason = "Unknown reason"
            }
            
            logger?.error?.write(msg: "Check failed: \(reason) with code \(rc)")
            throw DatabaseError(reason: reason, code: rc)
        }
    }
    
}
