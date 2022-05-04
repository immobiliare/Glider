//
//  File.swift
//  
//
//  Created by Daniele Margutti on 04/05/22.
//

import Foundation
import Network

internal enum StatusMonitor { }

// MARK: - Disk

extension StatusMonitor {
    
    class Disk {
        
        class var totalDiskSpaceInBytes: Int64 {
            do {
                let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
                let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value
                return space!
            } catch {
                return 0
            }
        }
        
        class var freeDiskSpaceInBytes: Int64 {
            do {
                let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
                let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value
                return freeSpace!
            } catch {
                return 0
            }
        }
        
        class var usedDiskSpaceInBytes: Int64 {
            totalDiskSpaceInBytes - freeDiskSpaceInBytes
        }
        
    }
    
}

// MARK: - Network

extension StatusMonitor {
    
    internal class Network {
        
        // MARK: - Public Properties

        static let current = Network()
        
        // MARK: - Private Properties
        
        private var pathMonitor: NWPathMonitor!
        private var path: NWPath?
        private let backgroudQueue = DispatchQueue.global(qos: .background)
        
        // MARK: - Initialization
        
        private init() {
            pathMonitor = NWPathMonitor()
            pathMonitor.pathUpdateHandler = self.pathUpdateHandler
            pathMonitor.start(queue: backgroudQueue)
        }
        
        // MARK: - Public Functions
        
        func isNetworkAvailable() -> Bool {
            guard let path = path, path.status == NWPath.Status.satisfied else {
                return false
            }
            
            return true
        }
        
        // MARK: - Private Functions
                
        private lazy var pathUpdateHandler: ((NWPath) -> Void) = { path in
            self.path = path
        }
        
    }
    
}

// MARK: - Memory

extension StatusMonitor {
    
    class Memory {
        
        // MARK: - Private Properties
        
        /// Formatter used to format bytes in human readable components.
        private lazy var formatter: ByteCountFormatter = {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .binary
            return formatter
        }()
        
        // MARK: - Public Properties
        
        /// Shared instance.
        static let current = Memory()
        
        /// Total physical memory expressed in bytes.
        let totalMemoryBytes: Float
        
        /// Used memory in bytes.
        var usedMemoryBytes: Float {
            var used_megabytes: Float = 0
            var info = mach_task_basic_info()
            var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
            
            let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    task_info(
                        mach_task_self_,
                        task_flavor_t(MACH_TASK_BASIC_INFO),
                        $0,
                        &count
                    )
                }
            }
            
            if kerr == KERN_SUCCESS {
                let used_bytes: Float = Float(info.resident_size)
                used_megabytes = used_bytes / 1024.0 / 1024.0
            }
            
            return used_megabytes
        }
        
        /// Free memory expressed in bytes.
        var freeMemoryBytes: Float {
            totalMemoryBytes - usedMemoryBytes
        }
        
        /// Return `true` when memory used is 90% of the total memory.
        var isLowMemory: Bool {
            (freeMemoryBytes / totalMemoryBytes) >= 0.9
        }
        
        // MARK: - Initiailization
        
        private init() {
            self.totalMemoryBytes = Float(ProcessInfo.processInfo.physicalMemory)
        }
        
    }
    
}
