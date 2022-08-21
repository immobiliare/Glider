# Glider

Glider is the logger for just about everything; it's like [winston](https://github.com/winstonjs/winston), but for iOS Mobile Apps!

**Glider is designed to be a simple, performant, universal logging library supporting multiple transports.**  
A transport is essentially a storage device for your logs.  
Each logger can have multiple transports configured at different levels; you can also customize how the messages are formatted.

Glider offers a comprehensive set of built-in transports, so you can easily plug and play the best solution for your application.

# Why Logging?

Logging and monitoring are fundamental parts of our job as engineers.  
Especially in mobile world (with very heterogeneous environments), you'll often find yourself in a situation where understanding how your software behaves in production is essential.
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
## Introduction

- [Logging](#logging)
  - [The Logger](#the-logger)
  - [Writing Messages](#writing-messages)
    - [Write Simple Message](#write-simple-message)
    - [Write with Closure](#write-with-closure)
    - [Write by passing Event](#write-by-passing-event)
  - [Interpolated Message](#interpolated-message)
  - [Disabling a Logger](#disabling-a-logger)
  - [Severity Levels](#severity-levels)
  - [Synchronous and Asynchronous Logging](#synchronous-and-asynchronous-logging)
    - [Synchronous Logging](#synchronous-logging)
    - [Asynchronous Logging](#asynchronous-logging)

## Formatters

- [Formatters](./Documentation/Formatters.md#formatters)
- [Archiviation](./Documentation/Formatters.md#archiviation)
  - [FieldsFormatter](./Documentation/Formatters.md#fieldsformatter)
  - [JSONFormatter](./Documentation/Formatters.md#jsonformatter)
  - [MsgPackDataFormatter](./Documentation/Formatters.md#msgpackdataformatter)
- [User Display (Console/Terminals)](./Documentation/Formatters.md#user-display-consoleterminals)
  - [TableFormatter](./Documentation/Formatters.md#tableformatter)
  - [TerminalFormatter](./Documentation/Formatters.md#terminalformatter)
  - [XCodeFormatter](./Documentation/Formatters.md#xcodeformatter)
  - [SysLogFormatter](./Documentation/Formatters.md#syslogformatter)

## Transports

- [Transports](./Documentation/Transports.md#transports)
  - [Introduction](./Documentation/Transports.md#introduction)
  - [Apple Swift-Log Integration](./Documentation/Transports.md#apple-swift-log-integration)
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
  - [RemoteTransport](./Documentation/Transports.md#remotetransport)
    - [RemoteTransportServer](./Documentation/Transports.md#remotetransportserver)
  - [SQLiteTransport](./Documentation/Transports.md#sqlitetransport)
  - [WebSocketTransport](./Documentation/Transports.md#websockettransport)
    - [WebSocketTransportClient](./Documentation/Transports.md#websockettransportclient)
    - [WebSocketTransportServer](./Documentation/Transports.md#websockettransportserver)
- [Other Transports](./Documentation/Transports.md#other-transports)
  - [GliderSentry](./Documentation/Transports.md#glidersentry)
  - [GliderELKTransport](./Documentation/Transports.md#gliderelktransport)
    - [ELK Features](./Documentation/Transports.md#elk-features)

## Network Sniffer

- [Network Sniffer](./Documentation/NetWatcher.md#network-sniffer)
  - [Introduction](./Documentation/NetWatcher.md#introduction)

# Installation

## Swift Package Manager

The Swift Package Manager is a tool for automating the distribution of Swift code and is integrated into the swift compiler. It is in early development, but Glider does support its use on supported platforms.

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