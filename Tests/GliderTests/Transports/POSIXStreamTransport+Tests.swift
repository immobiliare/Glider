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
import XCTest
@testable import Glider

@available(iOS 13.0.0, tvOS 13.0, *)
final class POSIXStreamsTransportTests: XCTestCase, POSIXStreamListenerDelegate {
    
    var stdListener: POSIXStreamListener?
    var expStdListener: XCTestExpectation?

    private var stdOutData = ""
    private var stdErrData = ""

    // MARK: - Tests
    
    /// The following test check if `POSIXStreamsTransportTests` transport layer
    /// by checking if appropriate messages are sent to the correct streams.
    /// 
    /// NOTE: disabled because it does not run correctly on GitHub Action.
    func _test_stdTransport() async throws {
        stdErrData = ""
        stdOutData = ""
        
        let stdTransport = StdStreamsTransport()

        // Validate stdout stream
        stdListener = POSIXStreamListener(streamType: .stdout)
        stdListener?.start(withDelegate: self)
        expStdListener = expectation(description: "Expect data for stdout")
                        
        let log = Log {
            $0.level = .trace
            $0.transports = [stdTransport]
        }
        
        log.info?.write({
            $0.message = "Message"
        })
          
        wait(for: [expStdListener!], timeout: 15)
        try stdListener?.stop()
        stdListener = nil
        expStdListener = nil
        
        // Validate stderr stream
        stdListener = POSIXStreamListener(streamType: .stderr)
        stdListener?.start(withDelegate: self)
        expStdListener = expectation(description: "Expect data for stderror")
        
        log.error?.write({
            $0.message = "Message"
        })

        wait(for: [expStdListener!], timeout: 15)
        try stdListener?.stop()
        stdListener = nil
        expStdListener = nil
        
        XCTAssertNotNil(stdOutData.isEmpty)
        XCTAssertTrue(stdOutData.contains("[INFO] Message"))
        XCTAssertTrue(stdOutData.contains("[ERROR] Message") == false)

        XCTAssertNotNil(stdErrData.isEmpty)
        XCTAssertTrue(stdErrData.contains("[ERROR] Message"))
        XCTAssertTrue(stdErrData.contains("[INFO] Message") == false)
    }
    
    // MARK: - OutputListenerDelegate
    
    func outputListener(_ listener: POSIXStreamListener, stream: POSIXStreamListener.StreamType,
                        receiveString string: String, fromHandle fileHandle: FileHandle) {
        
        if stream == .stderr{
            stdErrData += string
        } else if stream == .stdout  {
            stdOutData += string
        }
        expStdListener?.fulfill()
    }
    
    func outputListener(_ listener: POSIXStreamListener, stream: POSIXStreamListener.StreamType,
                        didOpenHandle fileHandle: FileHandle) { }
    func outputListener(_ listener: POSIXStreamListener, stream: POSIXStreamListener.StreamType,
                        willCloseHandle fileHandle: FileHandle) { }
    
}

// MARK: - Helper Class


/// Test helper for monitoring strings written to stdout.
public class POSIXStreamListener {
    
    public enum StreamType: Int32 {
        case stdout
        case stderr
        
        var fileName: String {
            switch self {
            case .stdout: return "/dev/stdout"
            case .stderr: return "/dev/stderr"
            }
        }
    }
    
    // MARK: - Public Properties
    
    public let streamType: StreamType
    
    /// Delegate for events.
    public weak var delegate: POSIXStreamListenerDelegate?
    
    // MARK: - Private Properties
    
    /// consumes the messages on STDOUT
    private var inputPipe: Pipe? = Pipe()
        
    /// File descriptor for stdout (aka STDOUT_FILENO)
    private var stdoutFileDescriptor: Int32 {
        FileHandle.standardOutput.fileDescriptor
    }

    /// File descriptor for stderr (aka STDERR_FILENO)
    private var stderrFileDescriptor: Int32 {
        FileHandle.standardError.fileDescriptor
    }
    
    /// Initialize a new listener for stream.
    ///
    /// - Parameter streamType: stream type.
    init(streamType: StreamType) {
        self.streamType = streamType
    }
    
    /// Sets up the "tee" of piped output, intercepting stdout then passing it through.
    ///
    /// ## [dup2 documentation](https://linux.die.net/man/2/dup2)
    /// `int dup2(int oldfd, int newfd);`
    /// `dup2()` makes `newfd` be the copy of `oldfd`, closing `newfd` first if necessary.
    func start(withDelegate delegate: POSIXStreamListenerDelegate?) {
        self.delegate = delegate
        
        dup2(inputPipe!.fileHandleForWriting.fileDescriptor, (streamType == .stdout ? STDOUT_FILENO : STDERR_FILENO))
        // listening on the readabilityHandler
        inputPipe!.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let self = self else {
                return
            }
            
            let data = handle.availableData
            if let string = String(data: data, encoding: .utf8), string.isEmpty == false {
                DispatchQueue.main.async {
                    self.delegate?.outputListener(self, stream: self.streamType, receiveString: string, fromHandle: handle)
                }
            }
        }
        
        delegate?.outputListener(self, stream: streamType, didOpenHandle: inputPipe!.fileHandleForReading)
    }

    func stop() throws {
        delegate?.outputListener(self, stream: streamType, willCloseHandle: inputPipe!.fileHandleForReading)

        // Restore
        let file: UnsafeMutablePointer<FILE> = pointerForStream(streamType)
        let fileName = streamType.fileName
        freopen(fileName, "a", file)
        
        if #available(iOS 13.0, tvOS 13.0, *) {
            try inputPipe?.fileHandleForWriting.close()
            try inputPipe?.fileHandleForReading.close()
        } else {
            inputPipe?.fileHandleForWriting.closeFile()
            inputPipe?.fileHandleForReading.closeFile()
        }
        
        inputPipe!.fileHandleForReading.readabilityHandler = nil
        inputPipe = nil
    }
    
    
    func pointerForStream(_ type: StreamType) -> UnsafeMutablePointer<FILE> {
        switch type {
        case .stdout: return stdout
        case .stderr: return stderr
        }
    }
    
}

// MARK: - OutputListenerDelegate

public protocol POSIXStreamListenerDelegate: AnyObject {
    
    func outputListener(_ listener: POSIXStreamListener, stream: POSIXStreamListener.StreamType,
                        receiveString string: String, fromHandle fileHandle: FileHandle)
    func outputListener(_ listener: POSIXStreamListener, stream: POSIXStreamListener.StreamType,
                        didOpenHandle fileHandle: FileHandle)
    func outputListener(_ listener: POSIXStreamListener, stream: POSIXStreamListener.StreamType,
                        willCloseHandle fileHandle: FileHandle)

}
