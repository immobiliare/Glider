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

#if os(Linux)
import CSQLite
#else
import SQLite3
#endif

extension SQLiteDb {
    
    public class Statement {
        
        // MARK: - Private Properties
        
        private var isOpen = false
        private var isFinalized = false
        private let sql: String
        private let stmt: OpaquePointer
        private let database: SQLiteDb
        private var paramIndex = 0

        // MARK: - Public Properties
        
        public static let autoParam = -1
        
        // MARK: - Initialization
        
        /// Initialize a statement object
        /// - Parameters:
        ///   - database: Database connection
        ///   - sql: SQL statement
        /// - Throws: Throws a DatabaseError for SQLite errors, tyipcally for syntax errors
        required public init(database: SQLiteDb, sql: String) throws {
            self.database = database
            self.sql = sql
            
            // Create statement
            var stmt: OpaquePointer?
            try database.check(sqlite3_prepare_v2(database.handle, sql, -1, &stmt, nil))
            self.stmt = stmt!
            
            SQLiteDb.logger?.info?.write(msg: "Prepare: \(sql)")
        }
        
        deinit {
            finalize()
        }
        
        // MARK: - Fetching
        
        private var lastResult: Int32 = SQLITE_OK
        
        /// Iterate rows of a select query.
        ///
        /// - Parameter handler: handler to parse the data.
        /// - Returns: an array of T
        public func iterateRows<T>(_ handler: ((_ columnCount: Int32, _ stmt: Statement) -> T?)) -> [T] {
            var parsedRows = [T]()
            
            let columnsCount = sqlite3_column_count(stmt)
            while lastResult == SQLITE_ROW {
                if let row = handler(columnsCount, self) {
                    parsedRows.append(row)
                }
                lastResult = sqlite3_step(stmt)
            }
            
            return parsedRows
        }
        
        // MARK: - Data Reading
        
        /// Retrieve the number of columns of a query result.
        ///
        /// - Returns: Int
        public func countColumns() -> Int {
            Int(sqlite3_column_count(stmt))
        }
        
        /// Get the column name.
        ///
        /// - Parameter column: Column index ('0' based)
        /// - Returns: The name of the column (if it exists)
        public func columnName(_ column: Int) -> String? {
            guard let ptr = sqlite3_column_name(stmt, Int32(column)) else {
                return nil
            }
            
            return String(cString: ptr)
        }
        
        /// Get the original table name for a column.
        ///
        /// - Parameter column: Column index (`0` based)
        /// - Returns: The name of the table owning this column (if it exists)
        public func tableName(_ column: Int) -> String? {
            guard let ptr = sqlite3_column_table_name(stmt, Int32(column)) else {
                return nil
            }
            
            return String(cString: ptr)
        }
        
        /// Get the original name of a column.
        ///
        /// - Parameter column: Column index (`0` based)
        /// - Returns: The name of the column, omitting aliases
        public func originName(_ column: Int) -> String? {
            guard let ptr = sqlite3_column_origin_name(stmt, Int32(column)) else {
                return nil
            }
            
            return String(cString: ptr)
        }
        
        /// Get the type of a column.
        ///
        /// - Parameter column: Column index (`0` based)
        /// - Returns: The column type of the current _value_
        public func columnType(_ column: Int) -> ColumnType {
            switch sqlite3_column_type(stmt, Int32(column)) {
            case SQLITE_INTEGER:
                return .integer
            case SQLITE_FLOAT:
                return .double
            case SQLITE_BLOB:
                return .data
            case SQLITE_NULL:
                return .null
            default:
                return .string
            }
        }
        
        /// Check if a certain value is null or not
        ///
        /// Normally, this is not required as the value accessors return optionals (by calling `isNull` internally)
        /// - Parameter column: Column index (zero based)
        /// - Returns: True if the column value is null, false if not
        public func isNull(column: Int) -> Bool {
            sqlite3_column_type(stmt, Int32(column)) == SQLITE_NULL
        }
        
        /// Retrieve a column value as an integer.
        ///
        /// - Parameter column: Column index (`0` based)
        /// - Returns: Int value or nil, if the value is null
        public func integer(column: Int) -> Int? {
            guard let res = int32(column: column) else {
                return nil
            }
            
            return Int(res)
        }
        
        /// Retrieve a column value as a date
        ///
        /// SQLite does not have a native date value, the number of milliseconds since 1970 is stored instead.
        /// - Parameter column: column: Column index (zero based)
        /// - Returns: Date or nil if the value is nil
        public func date(column: Int) -> Date? {
            guard !isNull(column: column) else {
                return nil
            }
            
            let value = sqlite3_column_int64(stmt, Int32(column))
            
            /// Initialize a date with milliseconds from midnight 1.1.1970 GMT
            return Date(timeIntervalSince1970: TimeInterval(value) / 1000)
        }
        
        /// Retrieve a column value as a boolean
        ///
        /// NOTE:
        ///     SQLite has no native BOOL value (though the keyword is accepted).
        ///     A BOOL `true` value is evaluated for a non zero integer expression.
        ///
        /// - Parameter column: column: Column index (`0` based)
        /// - Returns: Boolean value or nil, if the value is `null`.
        public func bool(column: Int) -> Bool? {
            guard !isNull(column: column) else {
                return nil
            }
            
            return sqlite3_column_int(stmt, Int32(column)) != 0
        }
        
        /// Retrieve a value as a Int64.
        ///
        /// - Parameter column: column: Column index (`0` based)
        /// - Returns: Int64 value or nil, if the value is null
        public func int64(column: Int) -> Int64? {
            guard !isNull(column: column) else {
                return nil
            }
            
            return sqlite3_column_int64(stmt, Int32(column))
        }
        
        /// Retrieve a value as an Int32.
        ///
        /// - Parameter column: column: Column index (`0` based)
        /// - Returns: Int32 value or nil, if the value is null
        public func int32(column: Int) -> Int32? {
            guard !isNull(column: column) else {
                return nil
            }
            
            return sqlite3_column_int(stmt, Int32(column))
        }
        
        /// Retrieve a value as a string.
        ///
        /// - Parameter column: column: Column index (`0` based)
        /// - Returns: String value or nil, if the value is null
        public func string(column: Int) -> String? {
            guard !isNull(column: column) else {
                return nil
            }
            
            return String(cString: sqlite3_column_text(stmt, Int32(column)))
        }
        
        /// Retrieve a value as a `Double`.
        ///
        /// - Parameter column: column: Column index (`0` based)
        /// - Returns: Double value or nil, if the value is null
        public func double(column: Int) -> Double? {
            guard !isNull(column: column) else {
                return nil
            }
            
            return sqlite3_column_double(stmt, Int32(column))
        }
        
        /// Retrieve a BLOB value as a `Data` instance.
        ///
        /// - Parameter column: column: Column index (`0` based)
        /// - Returns: Data value or nil, if the value is nil, the data value is copied, and therefore may outlive later `step(...)` calls
        public func data(column: Int) -> Data? {
            guard !self.isNull(column: column) else {
                return nil
            }
            
            let len = sqlite3_column_bytes(stmt, Int32(column))
            guard let ptr = sqlite3_column_blob(stmt, Int32(column)) else {
                fatalError("Expected a value")
            }
            
            return Data(bytes: ptr, count: Int(len))
        }
        
        /// Fetch and decode a JSON value, the value should be saved in either a data or string object,
        /// as defined in `Database.useJSON1`, **true** means use a string value, **false** means use a BLOB value.
        ///
        /// - Parameters:
        ///   - column: column: Column index (`0` based)
        /// - Returns: A decoded instance, if not null AND a successful conversion exists
        public func object<O: Decodable>(column: Int) -> O? {
            guard !isNull(column: column) else {
                return nil
            }
            
            let data: Data?
            if database.useJSON1 {
                guard let str = string(column: column) else {
                    return nil
                }
                
                data = str.data(using: .utf8)
            } else {
                data = self.data(column: column)
            }
            
            guard let cdata = data else {
                return nil
            }
            
            return try? database.jsonDecoder.decode(O.self, from: cdata)
        }
        
        /// Retrieve a UUID, please note that UUIDs are not really supported by sqlite,
        /// and are stored as plain text.
        ///
        /// - Parameter column: column: Column index (`0` based)
        /// - Returns: UUID value
        public func uuid(column: Int) -> UUID? {
            guard let text = string(column: column) else {
                return nil
            }
            
            return UUID(uuidString: text)
        }
        
        // MARK: Parameters Query
        
        /// Returns the number of parameters of this statement.
        /// NOTE: Parameters are indexed starting at 1.
        public var paramCount: Int {
            Int(sqlite3_bind_parameter_count(stmt))
        }
        
        /// Returns the parameter index for the parameter with name `name`.
        public func paramIndex(_ name: String) throws -> Int {
            Int(sqlite3_bind_parameter_index(stmt, name.cString(using: .utf8)))
        }
        
        /// Returns the parameter name of the parameter at index `idx`.
        public func paramName(_ idx: Int) throws -> String? {
            String(cString: sqlite3_bind_parameter_name(stmt, Int32(idx)))
        }
        
        // MARK: - Data Binding
        
        /// Bind an array of values to the statement.
        ///
        /// - Parameter values: values to bind.
        /// - Throws: throw an exception if something fails.
        public func bind(_ values: [Any?]) throws {
            guard !values.isEmpty else {
                return
            }
            
            // Reset bindings
            try reset()
            
            // Validate the expected params and received ones.
            let bindParamsCount = Int(sqlite3_bind_parameter_count(stmt))
            guard values.count == bindParamsCount else {
                fatalError("\(sqlite3_bind_parameter_count(stmt)) values expected, \(values.count) passed")
            }
            
            // Execute binding
            for idx in 1...values.count {
                try bind(values[idx - 1], idx)
            }
        }
        
        /// Bind a single value to a specified index.
        ///
        /// - Parameters:
        ///   - value: values to bind.
        ///   - idx: index.
        /// - Throws: throw an exception if binding fails.
        public func bind(_ value: Any?, _ idx: Int) throws {
            if value == nil {
                sqlite3_bind_null(stmt, Int32(idx))
            } else if let value = value as? Data {
                sqlite3_bind_blob(stmt, Int32(idx), value.bytes, Int32(value.bytes.count), SQLiteDb.SQLITE_TRANSIENT)
            } else if let value = value as? Double {
                sqlite3_bind_double(stmt, Int32(idx), value)
            } else if let value = value as? Int64 {
                sqlite3_bind_int64(stmt, Int32(idx), value)
            } else if let value = value as? String {
                sqlite3_bind_text(stmt, Int32(idx), value, -1, SQLiteDb.SQLITE_TRANSIENT)
            } else if let value = value as? Int {
                sqlite3_bind_int64(stmt, Int32(idx), Int64(value)) // just INTEGER
            } else if let value = value as? Bool {
                sqlite3_bind_int64(stmt, Int32(idx), Int64((value ? 1 : 0))) // just INTEGER
            } else if let value = value {
                fatalError("Tried to bind unexpected value \(value)")
            }
        }
        
        /// Bind a nil value.
        ///
        /// By default, the value is already bound to nil, however, this can be used for prepared statements to re-bind a value.
        ///
        /// It is recommended to `clearBindings` after a `reset()` instead.
        /// - Parameter param: Parameter number (1 based), when omitted, the parameters are added by their order
        /// - Throws: `DatabaseError`
        /// - Returns: Self
        @discardableResult
        public func bind(param: Int = autoParam) throws -> Self {
            let param = autoParamIndex(param)
            try check(sqlite3_bind_null(stmt, Int32(param)))
            
            return self
        }
        
        /// Bind an Int32 value to a statement.
        ///
        /// - Parameters:
        ///   - param: Parameter number (1 based), when omitted, the parameters are added by their order
        ///   - value: Int32 value, or nil
        /// - Throws: DatabaseError
        /// - Returns: Self , so binds could be chained: `stmt.bind("a").bind("b").bind(object)`
        @discardableResult
        public func bind(param: Int = autoParam, _ value: Int32?) throws -> Self {
            if let value = value {
                let param = autoParamIndex(param)
                return try check(sqlite3_bind_int(stmt, Int32(param), value))
            } else {
                return try bind(param: param)
            }
        }
        
        /// Bind an Int64 value to a statement
        /// - Parameters:
        ///   - param: Parameter number (1 based), when omitted, the parameters are added by their order
        ///   - value: Int64 value, or nil
        /// - Throws: DatabaseError
        /// - Returns: Self , so binds could be chained: `stmt.bind("a").bind("b").bind(object)`
        @discardableResult
        public func bind(param: Int = autoParam, _ value: Int64?) throws -> Self {
            if let value = value {
                let param = autoParamIndex(param)
                return try check(sqlite3_bind_int64(stmt, Int32(param), value))
            } else {
                return try bind(param: param)
            }
        }
        
        /// Bind an encodable parameter, depending on the `Database.useJSON1` value, the data is either saved as a blob when `useJSON1` is **false** or string when it is set to **true** (default).
        /// - Parameters:
        ///   - param: Parameter number (1 based), when omitted, the parameters are added by their order
        ///   - value: An encodable object
        /// - Throws: DatabaseError
        /// - Returns: Self , so binds could be chained: `stmt.bind("a").bind("b").bind(object)`
        @discardableResult
        public func bind<V: Encodable>(param: Int = autoParam, _ value: V?) throws -> Self {
            if let value = value {
                let data = try database.jsonEncoder.encode(value)
                if self.database.useJSON1 {
                    guard let json = String(data: data, encoding: .utf8) else {
                        throw DatabaseError(reason: "Error converting data to a UTF-8 string", code: -1)
                    }
                    return try bind(param: param, json)
                } else {
                    return try bind(param: param, data)
                }
            } else {
                return try bind(param: param)
            }
        }
        
        /// Bind a date value to a statement
        ///
        /// SQLite has no built in date type, instead, the number of milliseconds since 1970 is stored.
        /// - Parameters:
        ///   - param: Parameter number (1 based), when omitted, the parameters are added by their order
        ///   - value: Date value, or nil
        /// - Throws: DatabaseError
        /// - Returns: Self , so binds could be chained: `stmt.bind("a").bind("b").bind(object)`
        @discardableResult
        public func bind(param: Int = autoParam, _ value: Date?) throws -> Self {
            if let epoch = value?.timeIntervalSince1970 {
                let param = autoParamIndex(param)
                return try check(sqlite3_bind_int64(stmt, Int32(param), Int64(epoch)))
            } else {
                return try bind(param: param)
            }
        }
        /// Bind a Bool value to a statement
        /// - Parameters:
        ///   - param: Parameter number (1 based), when omitted, the parameters are added by their order
        ///   - value: Bool value, or nil
        /// - Throws: DatabaseError
        /// - Returns: Self , so binds could be chained: `stmt.bind("a").bind("b").bind(object)`
        @discardableResult
        public func bind(param: Int = autoParam, _ value: Bool?) throws -> Self {
            if let value = value {
                let param = autoParamIndex(param)
                return try check(sqlite3_bind_int(stmt, Int32(param), value ? 1 : 0))
            } else {
                return try bind(param: param)
            }
        }
        
        /// Bind an Int value to a statement
        /// - Parameters:
        ///   - param: Parameter number (1 based), when omitted, the parameters are added by their order
        ///   - value: Int value, or nil
        /// - Throws: DatabaseError
        /// - Returns: Self , so binds could be chained: `stmt.bind("a").bind("b").bind(object)`
        @discardableResult
        public func bind(param: Int = autoParam, _ value: Int?) throws -> Self {
            let value32: Int32?
            if let value = value {
                value32 = Int32(value)
            } else {
                value32 = nil
            }
            return try bind(param: param, value32)
        }
        
        /// Bind a string value to a statement
        /// - Parameters:
        ///   - param: Parameter number (1 based), when omitted, the parameters are added by their order
        ///   - value: String value, or nil
        /// - Throws: DatabaseError
        /// - Returns: Self , so binds could be chained: `stmt.bind("a").bind("b").bind(object)`
        @discardableResult
        public func bind(param: Int = autoParam, _ value: String?) throws -> Self {
            if let value = value {
                let param = autoParamIndex(param)
                return try check(sqlite3_bind_text(stmt, Int32(param), value, -1, SQLiteDb.SQLITE_TRANSIENT))
            } else {
                return try bind(param: param)
            }
        }
        
        /// Binds `null` to the parameter.
        /// - Parameter idx: index of the parameter destination of the binding.
        /// - Throws: throw an exception if binding fails
        public func bindNull(param idx: Int) throws {
            try database.check(sqlite3_bind_null(stmt, Int32(idx)))
        }
        
        /// Bind an Int32 double to a statement
        /// - Parameters:
        ///   - param: Parameter number (1 based), when omitted, the parameters are added by their order
        ///   - value: Double value, or nil
        /// - Throws: DatabaseError
        /// - Returns: Self , so binds could be chained: `stmt.bind("a").bind("b").bind(object)`
        @discardableResult
        public func bind(param: Int = autoParam, _ value: Double?) throws -> Self {
            if let value = value {
                let param = autoParamIndex(param)
                return try check(sqlite3_bind_double(stmt, Int32(param), value))
            } else {
                return try bind(param: param)
            }
        }
        
        /// Bind a data (BLOB) value to a statement
        /// - Parameters:
        ///   - param: Parameter number (1 based), when omitted, the parameters are added by their order
        ///   - value: Data value, or nil
        /// - Throws: DatabaseError
        /// - Returns: Self , so binds could be chained: `stmt.bind("a").bind("b").bind(object)`
        @discardableResult
        public func bind(param: Int = autoParam, _ value: Data?) throws -> Self {
            if let value = value {
                return try value.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
                    let param = autoParamIndex(param)
                    return try check(sqlite3_bind_blob(stmt, Int32(param), body.baseAddress, Int32(value.count), SQLiteDb.SQLITE_TRANSIENT))
                }
            } else {
                return try bind(param: param)
            }
        }
        
        /// Binds a uuid value to a statement, SQLite has no UUID support, so wer'e converting UUIDs to strings
        /// - Parameters:
        ///   - param: Parameter number (1 based), when omitted, the parameters are added by their order
        ///   - value: UUID value, or nil
        /// - Throws: DatabaseError
        /// - Returns: Self , so binds could be chained: `stmt.bind("a").bind("b").bind(object)`
        @discardableResult
        public func bind(param: Int = autoParam, _ value: UUID?) throws -> Self {
            return try bind(param: param, value?.uuidString)
        }
        
        // MARK: - Manage The State
        
        /// Step a statement
        ///
        /// Step is used to perform the statement, or to retrieve the next row.
        /// - When performing a statement that requires parameters, call the `bind(..)` variants before calling step
        /// - Bound parameters are not cleared after `step()` or `reset()`
        /// - Step may return a generic error, to retreive the specifc error, call `reset()`, I'm sorry, that's the way the SQLite API works
        /// - Step automatically calls `reset` after iterating all rows in SQLite > 3.6.23.1, and if the [SQLITE_OMIT_AUTORESET](https://sqlite.org/compile.html#omit_autoreset) compilation flag is not set, but it's recommended to call `reset` before reusing the statement.
        /// - Throws: DatabaseError
        /// - Returns: True if a row is available for fetch, false if not, a typical use of step would be:
        /// ```
        /// while try.stmt.step() {
        ///     fetch values from a query
        /// }
        /// // or
        /// let stmt = try Statement(database:db, sql:sql)
        /// try stmt.bind(param:1, "Hello")
        /// try stmt.step()
        /// try stmt.reset()
        /// try stmt.clearBindings()
        /// ```
        @discardableResult
        public func step() throws -> Bool {
            if !isOpen {
                isOpen = true
                
                // NOTE: 
                // `ExpressibleByStringLiteral` means to give we a shorthand
                // to invoke `init(stringLiteral value: String)` by a string literal expression.
                // Since string is not a literal, it cannot trigger this shorthand.
                // We have to call the initialiser explicitly.
                SQLiteDb.logger?.info?.write(msg: .init(stringLiteral: self.sql))
            }
            
            lastResult = sqlite3_step(stmt)
            switch lastResult {
            case SQLITE_ROW:
                return true
            case SQLITE_DONE:
                return false
            default:
                assert(lastResult != SQLITE_OK, "Invalid return code")
                try check(lastResult)
            }
            fatalError("Should never get here")
        }
        
        /// Reset the statement state, so it can be re used (by calling `step()`).
        /// NOTE:
        /// For some erros during `step()`, such as constaint violations, this method will throw a more specific error code.
        public func reset() throws {
            try check(sqlite3_reset(stmt))
            isOpen = false
            paramIndex = 0
        }
        
        /// Clear bindings set using the `bind(...)` variants.
        public func clearBindings() throws {
            try check(sqlite3_clear_bindings(stmt))
        }
        
        /// Finalizes the statement.
        ///
        /// NOTE:
        /// Do not reuse it after finalizing it.
        /// Automatically called when the object destructs, you only need to call
        /// this method if it is easier than making the object fall out of scope
        public func finalize() {
            guard !isFinalized else {
                return
            }
            
            isFinalized = true
            sqlite3_finalize(stmt)
        }
        
        // MARK: - Private Functions
        
        @discardableResult
        private func check(_ result: Int32) throws -> Self {
            try database.check(result)
            return self
        }
        
        private func autoParamIndex(_ value: Int) -> Int {
            guard value == Statement.autoParam else {
                return value
            }
            paramIndex += 1
            return paramIndex
        }
        
    }
    
}

// MARK: - SQLiteDb.Statement.ColumnType

extension SQLiteDb.Statement {
    
    /// Column type identifier
    /// The native type of the column can be identified using the method `type(column:Int) -> ColumnType`.
    /// It is still possible to cast data (where applicable) using a different accessor, for instance,
    /// it is possible to request an integer value as a string.
    ///
    /// - `double`: Column is a floating point value
    /// - `string`: Column represent a text value
    /// - `data`: Column represent a BLOB value
    /// - `integer`: Column represent an integer value.
    /// - `null`: Column is a null value (you cannot retrive a column type when value is null)
    public enum ColumnType {
        case double
        case string
        case data
        case integer
        case null
    }
    
}

// MARK: - Data Extension

fileprivate extension Data {
    
    var bytes: [UInt8] {
        return [UInt8](self)
    }
    
}
