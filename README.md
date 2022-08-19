# Glider

Glider is the logger for just about everything.  
You can think of Glider as the [winston](https://github.com/winstonjs/winston) for Swift ages!

**Glider is designed to be a simple, performant, universal logging library supporting multiple transports.**  
A transport is essentially a storage device for your logs.  
Each logger can have multiple transports configured at different levels; you can also customize how the messages are formatted.

Glider offers a comprehensive set of built-in transports, so you can easily plug and play the best solution for your application.

# Why Logging?

At Immobiliare, as with any other product company, logging and monitoring are fundamental parts of our job as engineers.  
Whether you are a backend engineer or a frontend one, you'll often find yourself in a situation where understanding how your software behaves in production is essential.
That's especially true in the mobile world, where you may encounter different settings, situations, and critical paths.
That's the right job for remote logging: logged data provide valuable information that would be difficult to gather otherwise, unveil unexpected behaviors and bugs, and even if the data was adequately anonymized, identify the sequences of actions of singular users.

# What you will get?

Creating a logger is simple.  
Each logger is an instance of `Log` class; typically, you need to specify one or more transports (where the data is stored).

```swift
let logger = Log {
 $0.subsystem = "com.myawesomeapp"
 $0.category = "storage"
 $0.level = .warning
 $0.transports = [ConsoleTransport()]
}
```

The following logger shows received messages - only warning or more severe - in the console.

```swift
logger.error?.write("Unexpected error has occurred!")
```

That's it!

# Why Glider will be your next logging solution?

We loved making this open-source package and would see engineers like you using this software.  
Those are 5 reasons you will love Glider:

- 🧩 14+ built-in, fully customizable transports to store your data ([ELK](https://github.com/malcommac/Glider/tree/main/GliderELK/Sources), [HTTP](https://github.com/malcommac/Glider/blob/main/Glider/Sources/Transports/HTTPTransport/HTTPTransport.swift), [Logstash](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Transports/LogstashTransport), [SQLite](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Transports/SQLiteTransport), [WebSocket](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Transports/WebSocketTransport), [Console](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Transports/Console), [File/Rotating Files](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Transports/File), [POSIX](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Transports/File/POSIXTransports), [swift-log](https://github.com/malcommac/Glider/tree/main/GliderSwiftLog/Sources), [sentry.io](https://github.com/malcommac/Glider/tree/main/GliderSentry/Sources)...)
- ✏️ 7+ customizable formatters for log messages ([JSON](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Formatters/JSONFormatter), [Fields based](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Formatters/FieldsFormatter)), [MsgPack](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Formatters/MsgPackFormatter), [Syslog](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Formatters/SysLogFormatter))...)
- 🚀 A simple APIs set with an extensible architecture to suit your need
- 📚 A fully documented code (check out our DoCC site!)
- ⚙️ An extensive unit test package

# API Documentation

APIs is fully documented using Apple DoCC.  
Click here to read it.
# Documentation

- [Logging](./Documentation/Logger.md#logging)
  - [The Logger](./Documentation/Logger.md#the-logger)
  - [Writing Messages](./Documentation/Logger.md#writing-messages)
    - [Write Simple Message](./Documentation/Logger.md#write-simple-message)
    - [Write with Closure](./Documentation/Logger.md#write-with-closure)
    - [Write by passing Event](./Documentation/Logger.md#write-by-passing-event)
  - [Interpolated Message](./Documentation/Logger.md#interpolated-message)
  - [Disabling a Logger](./Documentation/Logger.md#disabling-a-logger)
  - [Severity Levels](./Documentation/Logger.md#severity-levels)
  - [Synchronous and Asynchronous Logging](./Documentation/Logger.md#synchronous-and-asynchronous-logging)
    - [Synchronous Logging](./Documentation/Logger.md#synchronous-logging)
    - [Asynchronous Logging](./Documentation/Logger.md#asynchronous-logging)
- [Transports](./Documentation/Transports.md#transports)
  - [Introduction](./Documentation/Transports.md#introduction)
  - [Base Transports](./Documentation/Transports.md#base-transports)
    - [AsyncTransport](./Documentation/Transports.md#asynctransport)
  - [BufferedTransport](./Documentation/Transports.md#bufferedtransport)
  - [ThrottledTransport](./Documentation/Transports.md#throttledtransport)
- [Built-in Transports](./Documentation/Transports.md#built-in-transports)
  - [ConsoleTransport](./Documentation/Transports.md#consoletransport)
  - [OSLogTransport](./Documentation/Transports.md#oslogtransport)
  - [POSIXStreamTransport](./Documentation/Transports.md#posixstreamtransport)
  - [FileTransport](./Documentation/Transports.md#filetransport)
  - [SizeRotationFileTransport](./Documentation/Transports.md#sizerotationfiletransport)
  - [HTTPTransport](./Documentation/Transports.md#httptransport)

# Installation

## Swift Package Manager

The Swift Package Manager is a tool for automating the distribution of Swift code and is integrated into the swift compiler. It is in early development, but Willow does support its use on supported platforms.

Once you have your Swift package set up, adding Willow as a dependency is as easy as adding it to the dependencies value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "")
]
```
## CocoaPods

CocoaPods is a dependency manager for Cocoa projects.  
To integrate Willow into your project, specify it in your Podfile:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'
use_frameworks!

pod 'Glider'
```