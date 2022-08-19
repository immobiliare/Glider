# Transports

- [Transports](#transports)
  - [Introduction](#introduction)
  - [Base Transports](#base-transports)
    - [AsyncTransport](#asynctransport)
  - [BufferedTransport](#bufferedtransport)
  - [ThrottledTransport](#throttledtransport)
- [Built-in Transports](#built-in-transports)
  - [ConsoleTransport](#consoletransport)
  - [OSLogTransport](#oslogtransport)
  - [POSIXStreamTransport](#posixstreamtransport)
  - [FileTransport](#filetransport)
  - [SizeRotationFileTransport](#sizerotationfiletransport)

## Introduction

Writing log messages to various locations is an essential feature of any robust logging library.  
This is made possible in Glider through the `Transport` protocol:

```swift
public protocol Transport { 
    var queue: DispatchQueue? { get }
    var isEnabled: Bool { get set }
    var minimumAcceptedLevel: Level? { get set }

    @discardableResult
    func record(event: Event) -> Bool
}
```

- `queue`: represent the `DispatchQueue` used to store events. A serial queue is typically used, such as when the underlying log facility is inherently single-threaded and/or proper message ordering wouldn't be ensured otherwise. However, a concurrent queue may also be used, and might be appropriate when logging to databases or network endpoints. Typically each transport define its own queue and you should never need to modify it.
- `isEnabled`: allows to temporary disable a transport without disabling its parent `Log`.
- `minimumAcceptedLevel`: A filter by `severity` implemented at the transport level. You can, for example, create a logger which logs in `info` but for one of the transport (for example ELK or Sentry) it avoids to send messages with a severity lower than `error` in order to clog your remote service). When `nil` the message is not filtered and all messages accepted by the parent `Log` instance are accepted automatically.

> **Note**
> Moreover most transports also specify another common property called `formatters`.
> A Formatter is an object conform to `EventFormatter` protocol which allows to format the `Event`'s `message` and transform them as you need.  
> For example `ConsoleTransport` defines a single formatter used to print event messages in a style similar to a common XCode print statement (with timestamp, pid, message etc.).

The most important function of the protocol is the `record(event:)` function which receive `Event` instances coming from the parent `Log` instance and implement its own logic to store/send values.

## Base Transports

Glider offers several base transport layers you can use to simplify the creation of your own transport.

### AsyncTransport

`AsyncTransport` is a transport specifically made for asynchrouns request.  
It store logs locally in a temporary (in-memory) SQLite3 database; once a specified amount of messages are collected it allows to send them via a network request.

> **Note**
> Typically you don't need to use `AsyncTransport` as is. It powers the `HTTPTransport` transport service.

```swift
let config = AsyncTransport.Configuration {
    $0.autoFlushInterval = 3 // periodic flush interval called even if chunk size is not reached
    $0.bufferStorage = .inMemory // where the messages are temporary saved
    $0.chunksSize = 20 // how much events must contain each chunk at max
}
let transport = try AsyncTransport(delegate: self, configuration: config)

// The main message of the delegate
public func asyncTransport(_ transport: AsyncTransport,
                               canSendPayloadsChunk chunk: AsyncTransport.Chunk,
                               onCompleteSendTask completion: @escaping ((ChunkCompletionResult) -> Void)) {
    // Do something with the chunk of events collected
}
```

## BufferedTransport

The `BufferedTransport` is a generic event recorder that buffers the log messages passed to its `record(event:)` function.
Construction requires a `bufferedItemBuilder` function, which is responsible for converting the `event` and formatted message `SerializableData` into the generic `BufferItem` type.

## ThrottledTransport

The throttled transport is a tiny but thread-safe logger with a buffering and retrying mechanism for iOS.
Buffer is a limit cap when reached call the flush mechanism.  
You can also set a time interval to auto flush the content of the buffer regardless the number of currently stored payloads.

> **Note**
> Typically you don't need to use `ThrottledTransport` as is. It powers the `SQLiteTransport` transport service.

# Built-in Transports

## ConsoleTransport

`ConsoleTransport` is used to print log directly on Xcode or other IDE consoles. By default when initialized the console transport is initialized by setting the `XCodeFormatter`, an event message formatter used to print messages using the similar output of standard `NSLog()` or `print()` methods.

```swift
// This create a custom configuration of the `XCodeFormatter` which print
// print colored warning/error messages.
// NOTE: Xcode does not support colored console anymore so you need to install
// this font:
// https://raw.githubusercontent.com/jjrscott/ColoredConsole/master/ColoredConsole-Bold.ttf
// And set it as the font for Console fonts inside the settings panel of xcode.
let consoleTransport = ConsoleTransport {
    $0.minimumAcceptedLevel = .info // print only info or more severe messages even if the log specify .trace below
    // setup formatters
    $0.formatters = [
        XCodeFormatter(showCallSite: false, colorize: .onlyImportant)
    ]
}

let logger = Log {
    $0.level = .trace
    $0.transports = [consoleTransport]
}
```

## OSLogTransport

The `OSLogTransport` is an implemention of the `Transport` protocol that records log entries using the new unified logging system available s of iOS 10.0, macOS 10.12, tvOS 10.0, and watchOS 3.0.

More [informations here](https://developer.apple.com/documentation/os/logging).

```swift
let osLogTransport = OSLogTransport {
    $0.formatters = [SysLogFormatter()] // change the default formatter
    $0.levelTranslator = .strict // set strict mapping between glider's level and syslog
}

let logger = Log {
    $0.level = .trace
    $0.transports = [osLogTransport]
}
```

## POSIXStreamTransport

This transport can output text messages to POSIX stream.

```swift
// Dispatch messages to the std-out stream using the TerminalFormatter to format the output text.
let logger = Log {
    $0.level = .trace
    $0.transports = [
        StdStreamsTransport.stdOut(formatters: [TerminalFormatter()])
    ]
}
```

## FileTransport

A `FileTransport` implementation that appends log entries to a file.  
`FileTransport` is a simple log appender that provides no mechanism for file rotation or truncation. 

Unless you manually manage the log file when a `FileTransport` doesn't have it open, you will end up with an ever-growing file.

Use a `SizeRotationFileTransport` instead if you'd rather not have to concern yourself with such details.

```swift
// Create a trasnport to save a json formatted version of received events.
let fileURL = URL.temporaryFileURL()
let fileTransport = try FileTransport(fileURL: fileURL, {
    $0.formatters = [ JSONFormatter.standard()]
})
        
let log = Log {
    $0.level = .trace
    $0.transports = [fileTransport]
}
```

## SizeRotationFileTransport

`SizeRotationFileTransport` maintains a set of daily rotating log files, kept for a user-specified number of days.

`SizeRotationFileTransport` instance assumes full control over the log directory specified by its `directoryPath` property.

```swift
// Create a rotated files transport. It manages a directory where
// a maximum of 4 files of logs (500kb each) rotates by removing the
// oldest events.
// Events are saved in JSON format.
let directoryURL = try URL.newDirectoryURL()
let sizeLogTransport = try SizeRotationFileTransport(directoryURL: directoryURL) {
    $0.maxFilesCount = kilobytes(500)
    $0.maxFileSize = 4
    $0.filePrefix = "mylog_"
    $0.formatters = [JSONFormatter.standard()]
    $0.delegate = self
}
        
let log = Log {
    $0.level = .trace
    $0.transports = [sizeLogTransport]
}
```