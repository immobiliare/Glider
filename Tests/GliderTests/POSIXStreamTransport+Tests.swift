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
import XCTest
@testable import Glider

final class POSIXStreamsTransportTests: XCTestCase, OutputListenerDelegate {
    
    var stdOutListener = OutputListener(streamType: .stdout)
    var stdErrListener = OutputListener(streamType: .stderr)

    private var stdOutData = ""
    private var stdErrData = ""

    override func setUp() {
        super.setUp()
        
        stdErrData = ""
        stdOutData = ""
        
        stdOutListener.delegate = self
        stdOutListener.start()
        
        stdErrListener.delegate = self
        stdErrListener.start()
    }
    
    /// The following test check if `POSIXStreamsTransportTests` transport layer
    /// by checking if appropriate messages are sent to the correct streams.
    func test_stdTransport() {        
        let stdTransport = StdStreamsTransport()
        
        let log = Log {
            $0.level = .debug
            $0.transports = [stdTransport]
        }
                
        
        log.info?.write(event: {
            $0.message = "Info Message"
        })
        
        log.error?.write(event: {
            $0.message = "Error Message"
        })
        
        XCTAssertNotNil(stdOutData.isEmpty)
        XCTAssertTrue(stdOutData.contains("INFO Info Message"))

        XCTAssertNotNil(stdErrData.isEmpty)
        XCTAssertTrue(stdErrData.contains("ERROR Info Message"))
    }
    
    // MARK: - OutputListenerDelegate
    
    func outputListener(_ listener: OutputListener, stream: OutputListener.StreamType,
                        receiveString string: String, fromHandle fileHandle: FileHandle) {
        if stream == .stderr {
            stdErrData += string
        } else {
            stdOutData += string
        }
    }
    
    func outputListener(_ listener: OutputListener, stream: OutputListener.StreamType,
                        didOpenHandle fileHandle: FileHandle) { }
    func outputListener(_ listener: OutputListener, stream: OutputListener.StreamType,
                        didCloseHandle fileHandle: FileHandle) { }
    
}


/// Test helper for monitoring strings written to stdout.
public class OutputListener {
    
    public enum StreamType: Int32 {
        case stdout
        case stderr
    }
    
    // MARK: - Public Properties
    
    public let streamType: StreamType
    
    /// Delegate for events.
    public weak var delegate: OutputListenerDelegate?
    
    // MARK: - Private Properties
    
    /// consumes the messages on STDOUT
    private let inputPipe = Pipe()
    
    /// File descriptor for stdout (aka STDOUT_FILENO)
    private var stdoutFileDescriptor: Int32 {
        FileHandle.standardOutput.fileDescriptor
    }

    /// File descriptor for stderr (aka STDERR_FILENO)
    private var stderrFileDescriptor: Int32 {
        FileHandle.standardError.fileDescriptor
    }
    
    init(streamType: StreamType) {
        self.streamType = streamType
        
        inputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            let data = fileHandle.availableData
            if let string = String(data: data, encoding: String.Encoding.utf8) {
                self?.delegate?.outputListener(self!, stream: streamType, receiveString: string, fromHandle: fileHandle)
            }
        }
    }
    
    /// Sets up the "tee" of piped output, intercepting stdout then passing it through.
    ///
    /// ## [dup2 documentation](https://linux.die.net/man/2/dup2)
    /// `int dup2(int oldfd, int newfd);`
    /// `dup2()` makes `newfd` be the copy of `oldfd`, closing `newfd` first if necessary.
    func start() {
        var dupStatus: Int32

        let fileDescriptor: Int32 = fileDescriptorForStream(streamType)
        // Intercept STDOUT with inputPipe
        // newFileDescriptor is the pipe's file descriptor and the old file descriptor is STDOUT_FILENO
        dupStatus = dup2(inputPipe.fileHandleForWriting.fileDescriptor, fileDescriptor)
        // Status should equal newfd
        assert(dupStatus == fileDescriptor)
        delegate?.outputListener(self, stream: streamType, didOpenHandle: inputPipe.fileHandleForReading)
    }

    func stop() {
        freopen("/dev/stdout", "a", stdout) // Restore stdout
        [inputPipe.fileHandleForReading].forEach { file in
            file.closeFile()
            delegate?.outputListener(self, stream: streamType, didCloseHandle: file)
        }
    }
    
    deinit {
        stop()
    }
    
    func fileDescriptorForStream(_ type: StreamType) -> Int32 {
        switch type {
        case .stdout: return stdoutFileDescriptor
        case .stderr: return stderrFileDescriptor
        }
    }
    
}

// MARK: - OutputListenerDelegate

public protocol OutputListenerDelegate: AnyObject {
    
    func outputListener(_ listener: OutputListener, stream: OutputListener.StreamType,
                        receiveString string: String, fromHandle fileHandle: FileHandle)
    func outputListener(_ listener: OutputListener, stream: OutputListener.StreamType,
                        didOpenHandle fileHandle: FileHandle)
    func outputListener(_ listener: OutputListener, stream: OutputListener.StreamType,
                        didCloseHandle fileHandle: FileHandle)

}
