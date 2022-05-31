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
import SQLite3

// MARK: - SQLiteDB.Error

extension SQLiteDb {
    
    /// Database error
    public struct DatabaseError : Error, CustomStringConvertible {
        public let reason : String
        public let code : Int32
        
        public var description: String {
            "'\(reason)' (code=\(code))"
        }
    }
    
}

// MARK: - SQLiteDB.Options

extension SQLiteDb {
    
    /// Options to manage database.
    public struct Options {
        var openMode: OpenMode = .create
        var cacheMode: Cache = .sharedCache
        var threadMode: ThreadMode = .fullMutex
        var protection: Protection = .none
        
        public init() {}
    }
    
}

// MARK: - SQLiteDb.Location

extension SQLiteDb {
    
    /// The location of a SQLite database.
    ///
    /// - `inMemory`: An in-memory database (equivalent to `.uri(":memory:")`).
    ///              See: <https://www.sqlite.org/inmemorydb.html#sharedmemdb>
    /// - `temporary`: A temporary, file-backed database (equivalent to `.uri("")`).
    ///               See: <https://www.sqlite.org/inmemorydb.html#temp_db>
    /// - `fileURL`: A database located at the given URI filename (or path).
    ///             See: <https://www.sqlite.org/uri.html>
    public enum Location: CustomStringConvertible {
        case inMemory
        case temporary
        case fileURL(URL)
        
        public var description: String {
            switch self {
            case .inMemory:         return ":memory:"
            case .temporary:        return ""
            case .fileURL(let URL): return URL.path
            }
        }
        
        /// Return `true` if a local file exists when location is `fileURL`. Otherwise it will return always `false`.
        internal var fileExists: Bool {
            switch self {
            case .fileURL(let URL):
                return FileManager.default.fileExists(atPath: URL.path)
            default:
                return false
            }
        }
        
    }
    
}

// MARK: - SQLiteDb.OpenMode

extension SQLiteDb {
    
    /// Defines how to open new database in SQLite3.
    public struct OpenMode: OptionSet {
        
        public let rawValue: Int32

        /// The database is opened in read-only mode.
        /// If the database does not already exist, an error is returned.
        public static let readOnly = OpenMode(rawValue: SQLITE_OPEN_READONLY)
        
        /// The database is opened for reading and writing if possible, or reading only
        /// if the file is write protected by the operating system.
        /// In either case the database must already exist, otherwise an error is returned.
        public static let readWrite = OpenMode(rawValue: SQLITE_OPEN_READWRITE)
        
        /// The database is opened for reading and writing,
        /// and is created if it does not already exist.
        public static let create = OpenMode(rawValue: SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE)
        
        public init(rawValue:Int32){
            self.rawValue = rawValue
        }
        
    }
    
}

// MARK: - SQLiteDb.ThreadMode

extension SQLiteDb {
    
    /// Threading model for database open
    /// Defines the threading management mode used to perform operastions with database.
    ///
    /// - `noMutex`: The new database connection will use the "multi-thread" threading mode.
    ///              This means that separate threads are allowed to use SQLite at the same time,
    ///              as long as each thread is using a different database connection.
    /// - `fullMutex`: The new database connection will use the "serialized" threading mode.
    ///                This means the multiple threads can safely attempt to use the same
    ///                database connection at the same time.
    ///                (Mutexes will block any actual concurrency, but in this mode there is no harm in trying.)
    public enum ThreadMode {
        case noMutex
        case fullMutex
        
        internal var flag: Int32 {
            switch self {
            case .noMutex: return SQLITE_OPEN_NOMUTEX
            case .fullMutex: return SQLITE_OPEN_FULLMUTEX
            }
        }
    }
    
}

// MARK: - SQLiteDb.Cache

extension SQLiteDb {
    
    /// The following options are used to open the database connection.
    /// More infos can be found here <https://www.sqlite.org/sharedcache.html>
    ///
    /// - `sharedCache`: The database is opened shared cache enabled
    /// - `privateCache`: The database is opened shared cache disabled,
    public enum Cache {
        case sharedCache
        case privateCache
    
        internal var flag: Int32 {
            switch self {
            case .sharedCache: return SQLITE_OPEN_SHAREDCACHE
            case .privateCache: return SQLITE_OPEN_PRIVATECACHE
            }
        }
    }
    
}

// MARK: - SQLiteDb.Protection

extension SQLiteDb {
    
    public enum Protection {
        case protectComplete
        case protectCompleteUnlessOpen
        case protectCompleteUntilFirstUserAuth
        case none
    
        internal var flag: Int32 {
            switch self {
            case .protectComplete: return SQLITE_OPEN_FILEPROTECTION_COMPLETE
            case .protectCompleteUnlessOpen: return SQLITE_OPEN_FILEPROTECTION_COMPLETEUNLESSOPEN
            case .protectCompleteUntilFirstUserAuth: return SQLITE_OPEN_FILEPROTECTION_COMPLETEUNTILFIRSTUSERAUTHENTICATION
            case .none: return SQLITE_OPEN_FILEPROTECTION_NONE
            }
        }
    }
    
}

// MARK: - SQLiteDb.JournalMode

extension SQLiteDb {
    
    /// Transaction journal mode.
    /// See [documentation](https://www.sqlite.org/pragma.html#pragma_journal_mode) at the SQLite website.
    ///
    /// - `delete`: The DELETE journaling mode is the normal behavior. In the DELETE mode,
    ///             the rollback journal is deleted at the conclusion of each transaction.
    ///             Indeed, the delete operation is the action that causes the transaction to commit.
    ///             (See the document titled Atomic Commit In SQLite for additional detail.)
    /// - `truncate`: The TRUNCATE journaling mode commits transactions by truncating the rollback journal
    ///               to zero-length instead of deleting it. On many systems, truncating a file is much faster
    ///               than deleting the file since the containing directory does not need to be changed.
    /// - `persist`: The PERSIST journaling mode prevents the rollback journal from being deleted at the
    ///              end of each transaction. Instead, the header of the journal is overwritten with zeros.
    ///              This will prevent other database connections from rolling the journal back. The PERSIST
    ///              journaling mode is useful as an optimization on platforms where deleting or truncating
    ///              a file is much more expensive than overwriting the first block of a file with zeros.
    ///
    ///              See also: (PRAGMA journal_size_limit)[https://www.sqlite.org/pragma.html#pragma_journal_size_limit]
    ///              and [SQLITE_DEFAULT_JOURNAL_SIZE_LIMIT](https://www.sqlite.org/compile.html#default_journal_size_limit).
    ///  - `memory`: The WAL journaling mode uses [a write-ahead log](https://www.sqlite.org/wal.html) instead of a
    ///              rollback journal to implement transactions. The WAL journaling mode is persistent;
    ///              after being set it stays in effect across multiple database connections and after
    ///              closing and reopening the database. A database in WAL journaling mode can only be
    ///              accessed by SQLite version 3.7.0 (2010-07-21) or later.
    ///  - `wal`: The WAL journaling mode uses [a write-ahead log](https://www.sqlite.org/wal.html) instead of a rollback
    ///           journal to implement transactions. The WAL journaling mode is persistent; after being set it stays in
    ///           effect across multiple database connections and after closing and reopening the database.
    ///           A database in WAL journaling mode can only be accessed by SQLite version 3.7.0 (2010-07-21) or later.
    ///  - `off`: The OFF journaling mode disables the rollback journal completely. No rollback journal is ever created
    ///           and hence there is never a rollback journal to delete. The OFF journaling mode disables the atomic commit
    ///           and rollback capabilities of SQLite. The ROLLBACK command no longer works; it behaves in an undefined way.
    ///           Applications must avoid using the ROLLBACK command when the journal mode is OFF. If the application crashes
    ///           in the middle of a transaction when the OFF journaling mode is set, then the database file will very likely go corrupt.
    ///           Without a journal, there is no way for a statement to unwind partially completed operations following a constraint error.
    ///           This might also leave the database in a corrupted state.
    ///           For example, if a duplicate entry causes a CREATE UNIQUE INDEX statement to fail half-way through,
    ///           it will leave behind a partially created, and hence corrupt, index.
    ///           Because OFF journaling mode allows the database file to be corrupted using ordinary SQL,
    ///           it is disabled when SQLITE_DBCONFIG_DEFENSIVE is enabled.
    public enum JournalMode : String {
        case delete
        case truncate
        case persist
        case memory
        case wal
        case off
    }
    
}

// MARK: - SQiteDb.AutoVacuum

extension SQLiteDb {
    
    /// Set auto vacuum mode, auto-vacuuming is only possible if the database stores some additional
    /// information that allows each database page to be traced backwards to its referrer.
    /// Therefore, auto-vacuuming must be turned on before any tables are created.
    /// It is not possible to enable or disable auto-vacuum after a table has been created.
    ///
    /// - `none`: The default setting for auto-vacuum is 0 or "none", unless the
    ///           SQLITE_DEFAULT_AUTOVACUUM compile-time option is used. The "none" setting
    ///           means that auto-vacuum is disabled.
    ///            When auto-vacuum is disabled and data is deleted data from a database, the database f
    ///            ile remains the same size. Unused database file pages are added to a "freelist" and reused for subsequent inserts.
    ///            So no database file space is lost. However, the database file does not shrink.
    ///            In this mode the VACUUM command can be used to rebuild the entire database file and thus reclaim unused disk space.
    /// - `full`: When the auto-vacuum mode is 1 or "full", the freelist pages are moved to the end of the database
    ///           file and the database file is truncated to remove the freelist pages at every transaction commit.
    ///           Note, however, that auto-vacuum only truncates the freelist pages from the file.
    ///           Auto-vacuum does not defragment the database nor repack individual database pages the way that the VACUUM command does.
    ///           In fact, because it moves pages around within the file, auto-vacuum can actually make fragmentation worse.
    /// - `incrmeental`: When the value of auto-vacuum is 2 or "incremental" then the additional information needed to do auto-vacuuming
    ///                  is stored in the database file but auto-vacuuming does not occur automatically at each commit as it does
    ///                  with auto_vacuum=full. In incremental mode, the separate incremental_vacuum pragma must be invoked
    ///                  to cause the auto-vacuum to occur (See `func incrementalVacuum(pages:Int? = nil,schema:String? = nil) throws`)
    public enum AutoVacuum: Int {
        case none = 0
        case full = 1
        case incremental = 2
    }
    
}

extension SQLiteDb {
    
    /// See [Checkpoint a database](https://sqlite.org/c3ref/wal_checkpoint_v2.html)
    ///
    /// - `passive`: `SQLITE_CHECKPOINT_PASSIVE`.
    ///              Checkpoint as many frames as possible without waiting for any database readers or writers to finish,
    ///              then sync the database file if all frames in the log were checkpointed.
    ///              The busy-handler callback is never invoked in the SQLITE_CHECKPOINT_PASSIVE mode.
    ///              On the other hand, passive mode might leave the checkpoint unfinished if there are concurrent readers or writers.
    /// - `full`: `SQLITE_CHECKPOINT_FULL`
    ///           This mode blocks (it invokes the busy-handler callback) until there is no database writer and all readers
    ///           are reading from the most recent database snapshot.
    ///           It then checkpoints all frames in the log file and syncs the database file.
    ///           This mode blocks new database writers while it is pending, but new database readers are allowed to continue unimpeded.
    /// - `restart`: `SQLITE_CHECKPOINT_RESTART`
    /// - `truncate`: `SQLITE_CHECKPOINT_TRUNCATE`
    ///              This mode works the same way as SQLITE_CHECKPOINT_FULL with the addition that after checkpointing
    ///              the log file it blocks (calls the busy-handler callback) until all readers are reading from the
    ///              database file only. This ensures that the next writer will restart the log file from the beginning.
    ///              Like SQLITE_CHECKPOINT_FULL, this mode blocks new database writer attempts while it is pending,
    ///              but does not impede readers.
    public enum CheckpointMode {
        case passive
        case full
        case restart
        case truncate
        
        internal var flag : Int32 {
            switch self {
            case .full:     return SQLITE_CHECKPOINT_FULL
            case .passive:  return SQLITE_CHECKPOINT_PASSIVE
            case .restart:  return SQLITE_CHECKPOINT_RESTART
            case .truncate: return SQLITE_CHECKPOINT_TRUNCATE
            }
        }
    }
    
}

// MARK: - SQLiteDb.Version

extension SQLiteDb {
    
    /// Version type .
    /// - `data`: See [PRAGMA data_version](https://sqlite.org/pragma.html#pragma_data_version)
    /// - `schema`: See [PRAGMA schema_version](https://sqlite.org/pragma.html#pragma_schema_version)
    /// - `user`: See [PRAGMA user_version](https://sqlite.org/pragma.html#pragma_user_version)
    public enum Version : String {
        case data = "data_version"
        case schema = "schema_version"
        case user = "user_version"
    }
    
}
