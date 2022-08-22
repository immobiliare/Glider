# Transports

- [Transports](#transports)
  - [Introduction](#introduction)
  - [Apple Swift-Log Integration](#apple-swift-log-integration)
  - [Base Transports](#base-transports)
    - [AsyncTransport](#asynctransport)
    - [BufferedTransport](#bufferedtransport)
    - [ThrottledTransport](#throttledtransport)
- [Console Formatters](#console-formatters)
  - [ConsoleTransport](#consoletransport)
  - [OSLogTransport](#oslogtransport)
  - [POSIXStreamTransport](#posixstreamtransport)
- [File Formatters](#file-formatters)
  - [FileTransport](#filetransport)
  - [SizeRotationFileTransport](#sizerotationfiletransport)
  - [SQLiteTransport](#sqlitetransport)
- [Remote Formatters](#remote-formatters)
  - [HTTPTransport](#httptransport)
  - [RemoteTransport](#remotetransport)
    - [RemoteTransportServer](#remotetransportserver)
  - [WebSocketTransport](#websockettransport)
    - [WebSocketTransportClient](#websockettransportclient)
    - [WebSocketTransportServer](#websockettransportserver)
- [Third Party Transports](#third-party-transports)
  - [GliderSentry](#glidersentry)
  - [GliderELKTransport](#gliderelktransport)
    - [ELK Features](#elk-features)

## Introduction

A transport is essentially a storage device for your logs.  
Each logger can have multiple transports configured at different levels; you can also customize how the messages are formatted.

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
> Moreover, most transports also specify another common property called `formatters`.
> A Formatter is an object that conforms to `EventFormatter` protocol, which allows you to format the `Event`'s `message` and transform them as you need.  
> For example, `ConsoleTransport` defines a single formatter used to print event messages in a style similar to a common XCode print statement (with a timestamp, PID, message, etc.).

The most important function of the protocol is the `record(event:)` function which receives `Event` instances coming from the parent `Log` instance and implements its own logic to store/send values.

## Apple Swift-Log Integration

Glider can also work as a backend for [apple/swift-log](https://github.com/apple/swift-log/).  

The `GliderSwiftLogHandler` offers a `LogHandler` object which you can assign to the swift-log settings to use Glider as the backend:

```swift
LoggingSystem.bootstrap {
    var handler = GliderSwiftLogHandler(label: loggerName, logger: gliderLogger)
    handler.logLevel = .trace
    return handler
}
```
## Base Transports

Glider offers several base transport layers you can use to simplify the creation of your own transport.

### AsyncTransport

`AsyncTransport` is a transport specifically made for asynchronous requests.  
It stores logs locally in a temporary (in-memory) SQLite3 database; once a specified amount of messages are collected it allows to send them via a network request.

> **Note**
> Typically, you don't need to use `AsyncTransport` as is. It powers the `HTTPTransport` transport service.

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

### BufferedTransport

The `BufferedTransport` is a generic event recorder that buffers the log messages passed to its `record(event:)` function.
Construction requires a `bufferedItemBuilder` function, which is responsible for converting the `event` and formatted message `SerializableData` into the generic `BufferItem` type.

### ThrottledTransport

The throttled transport is a tiny but thread-safe logger with a buffering and retrying mechanism for iOS.
Buffer is a limit cap; when reached, call the flush mechanism.  
You can also set a time interval to auto flush the content of the buffer regardless the number of currently stored payloads.

> **Note**
> Typically, you don't need to use `ThrottledTransport` as is. It powers the `SQLiteTransport` transport service.

# Console Formatters

## ConsoleTransport

`ConsoleTransport` is used to print logs directly on Xcode or other IDE consoles. By default, when initialized, the console transport is initialized by setting the `XCodeFormatter` an event message formatter used to print messages using the similar output of standard `NSLog()` or `print()` methods.

```swift
// This creates a custom configuration of the `XCodeFormatter`, which print
// print colored warning/error messages.
// NOTE: Xcode does not support colored console anymore, so you need to install
// this font:
// https://raw.githubusercontent.com/jjrscott/ColoredConsole/master/ColoredConsole-Bold.ttf
// And set it as the font for Console fonts inside the settings panel of XCode.
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

# File Formatters

## FileTransport

A `FileTransport` implementation that appends log entries to a local file. 
`FileTransport` is a simple log appender that provides no mechanism for file rotation or truncation. 

Unless you manually manage the log file when a `FileTransport` doesn't have it open, you will end up with an ever-growing file.

> **Note**
> Use a `SizeRotationFileTransport` instead if you'd rather not have to concern yourself with such details.

```swift
// Create a trasnport to save a json formatted version of received events.
let fileURL = URL.temporaryFileURL()
let fileTransport = try FileTransport(fileURL: fileURL, {
    $0.formatters = [ JSONFormatter.standard() ] // output format as JSON payloads
})
        
let logger = Log {
    $0.level = .trace
    $0.transports = [fileTransport]
}
```

## SizeRotationFileTransport

`SizeRotationFileTransport` is the evolution of `FileTransport`: it maintains a set of daily rotating log files, kept for a user-specified number of days.  
`SizeRotationFileTransport` instance assumes full control over the log directory specified by its `directoryPath` property.

```swift
// Create a rotated files transport. It manages a directory where
// a maximum of 4 files of logs (500kb each) rotates by removing the
// oldest events.
// Events are saved in JSON format.
let directoryURL = try URL.newDirectoryURL()
let rotateFilesTransport = try SizeRotationFileTransport(directoryURL: directoryURL) {
    $0.maxFileSize = kilobytes(500) // maximum size per file
    $0.maxFilesCount = 4 // max number of logs
    $0.filePrefix = "mylog_" // custom file name
    $0.formatters = [JSONFormatter.standard()] // output format for events
}
        
let logger = Log {
    $0.level = .trace
    $0.transports = [rotateFilesTransport]
}
```

## SQLiteTransport

`SQLiteTransport` offers the ability to store events in a compact, searchable local sqlite3 database.  
We strongly suggest using this database when you need to collect the relevant amount of data; it offers great reliability, and it's fast.

```swift
// create an local database at given url
let sqliteTransport = try SQLiteTransport(databaseLocation: .fileURL(url), {
    // this transport used the ThrottledTransport as helper in order to optimize
    // how the events are stored (we would avoid creating a SQL transaction per each
    // event, so we connect enough data before making a single atomic transaction).
    $0.throttledTransport = .init({
        // Size of the buffer.
        // Keep in mind: a big size may impact to the memory. 
        // Tiny sizes may impact on storage service load.
        $0.maxEntries = 100
        // if not enough events (maxEntries) are collected in this interval do a transaction and flush data.
        $0.autoFlushInterval = 5
    })
    $0.delegate = self // listen for events
})
        
let logger = Log {
    $0.level = .trace
    $0.transports = [sqliteTransport]
}                
```

# Remote Formatters

## HTTPTransport

The `HTTPTransport` is used to send log events directly to an HTTP service by executing network calls to a specific endpoint.

It's up to the delegate (`HTTPTransportDelegate`) to produce a list of `HTTTransportRequest` requests which will be then executed and handled automatically by the transport.  
It also supports a retry mechanism in case of network errors.

```swift
let transport = try HTTPTransport(delegate: self) {
    $0.maxConcurrentRequests = 3 // 3 concurrent network request at max
    $0.formatters = [SysLogFormatter()] // setup the format of output to syslog
    $0.maxEntries = 100 // maximum number of events storable (LIFO)
    $0.chunkSize = 5 // number of events per each request
    $0.autoFlushInterval = 5 // auto flush interval each 5 seconds
}
transport.delegate = self

let log = Log {
    $0.transports = [transport]
    $0.level = .trace
}
```

The `HTTPTransportDelegate` should implement at least the method to produce the `URLRequest` used to send data to a remote web service:

```swift
 // MARK: - HTTPTransportDelegate
    
func httpTransport(_ transport: HTTPTransport,
                   prepareURLRequestsForChunk chunk: AsyncTransport.Chunk) -> [HTTPTransportRequest] {
        
    chunk.map { event, message, attempt in
        var urlRequest = URLRequest(url: URL(string: "http://myendoint:10450/receive.php")!)
        urlRequest.httpBody = message?.asData()
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 10
        return HTTPTransportRequest(urlRequest: urlRequest) {
            $0.maxRetries = 2 // 2 maximum retry on connection errors
        }
    }
}
```

## RemoteTransport

The `RemoteTransport` is used to send log in a custom binary format to a LAN/WAN destination.
It uses Bonjour/ZeroConfig to found active server where to send data.

> **Warning**
> Be sure to set the following keys in your app's `Info.plist`:
>
> ```xml
> <key>NSLocalNetworkUsageDescription</key>
>    <string>Network usage required for debugging activities</string>
> <key>NSBonjourServices</key>
> <array>
>    <string>_glider._tcp</string>
> </array>
> ```

Example:

```swift
let remoteTransport = try RemoteTransport(serviceType: self.serviceType, delegate: nil, {
    $0.autoConnectServerName = serverName // automatically search & connect to this server name
})

let logger = Log {
    $0.transports = [remoteTransport]
}
```

> **Note**
> We suggest to use a single shared instance of this transport for all of yours loggers.
> In this case use the `RemoteTransport.shared` shortcut instead of creating a new one.

### RemoteTransportServer

Gliders also offer a server so you can easily capture client connections from `RemoteTransport` instance:

```swift
let server = RemoteTransportServer(serviceName: serverName, serviceType: serviceType, delegate: self)
try self.server?.start()
```

Then you can use the `RemoteTransportServerDelegate` in order to receive events from connected clients:

```swift
func remoteTransportServer(_ server: RemoteTransportServer,
                           client: RemoteTransportServer.Client,
                           didReceiveEvent event: Event) {
    print("New event received from client: \(event.message)")
}
```

## WebSocketTransport

### WebSocketTransportClient

The `WebSocketTransportClient` is used to transport messages to a WebSocket compliant server.
Each message is transmitted to the server directly on the record.

> **Note**
> In order to optimize message transmission, we strongly suggest using a binary format
> like `MsgPackFormatter`.

```swift
  // We are using a custom textual format for message output.
  // It just includes the timestamp, severity and message.
  // (note: we're not sending attached `object` or `extra`/`tags` data, neither other context).
let customFormat = FieldsFormatter(fields: [
    .timestamp(),
    .message({
        $0.truncate = .head(length: 10)
    }),
])

let wsTransport = try WebSocketTransportClient(url: "ws://localhost:1011", delegate: self) {
    $0.connectAutomatically = true
    $0.formatters = [customFormat]
    $0.dataType = .event(encoder: JSONEncoder())
}
                
let logger = Log {
    $0.level = .trace // send any message, including low priority events like `trace` or `info`.
    $0.transports = [wsTransport]
}
```

### WebSocketTransportServer

You can also create a server and send events directly to any connected client.
Just create a `WebSocketTransportServer` transport:

```swift
    let transport = try WebSocketTransportServer(port: port, delegate: self, {
    $0.startImmediately = true
    $0.formatters = [customFormat]
})
```

and use `delegate` with `WebSocketTransportServerDelegate` to listen for useful events coming from the server (connection and/or disconnection by clients or any other error).

# Third Party Transports

Glider also offer other transports used to connect and send events to specific destinations.  
These transports are not part of the core package, so you need to install them along with the main library using relative podspecs or SPM packages.

## GliderSentry

The `GliderSentryTransport` is used to forward the messages coming from `Glider` logging system to the [Sentry](https://github.com/getsentry/sentry-cocoa) iOS official SDK.  
When you install this package, `sentry-cocoa` is a dependency.

```swift
let sentryTransport = GliderSentryTransport {
    // If you have not initialized the Sentry SDK yet you can pass a valid
    // `sdkConfiguration` here and the lib will do it for you.
    $0.sdkConfiguration = { ... }
    $0.environment = "MyApp-Production" // set the sentry environment
}

let logger = Log {
    $0.level = .info
    $0.transports = [sentryTransport]
}
```

## GliderELKTransport

The `GliderELKTransport` library provides a logging transport for glider and [ELK](https://www.elastic.co/elastic-stack?ultron=B-Stack-Trials-EMEA-S-Exact&gambit=Stack-ELK&blade=adwords-s&hulk=paid&Device=c&thor=elk%20stack&gclid=Cj0KCQjwjIKYBhC6ARIsAGEds-I1kAzd4o5RdmCR0U4yXPL4QFQXBCn1bRn-MjwZV0fkSXuFIIJ6VcwaAo1AEALw_wcB) environments.  

The log entries are properly formatted, cached, and then uploaded via HTTP/HTTPS to elastic/logstash, which allows for further processing in its pipeline. The logs can then be stored in elastic/elasticsearch and visualized in elastic/kibana.  

> **Note**
> The original inspiration is from [swift-log-elk](https://github.com/Apodini/swift-log-elk) project.

### ELK Features
- Uploads the log data automatically to Logstash (e.g. the ELK stack)
- Caches the created log entries and sends them via HTTP either periodically or when exceeding a certain configurable memory threshold to Logstash
- Converts the logging metadata to a JSON representation, which allows querying after those values (e.g. filter after a specific parameter in Kibana)
- Logs itself via a background activity logger (including protection against a possible infinite recursion)

```swift
let elkTransport = try GliderELKTransport(hostname: "127.0.0.1", port: 5000, delegate: self) {
    $0.uploadInterval = TimeAmount.seconds(10)
}
        
let logger = Log {
    $0.subsystem = "com.myapp"
    $0.category = "network"
    $0.level = .info
    $0.transports = [elkTransport]
}
```
