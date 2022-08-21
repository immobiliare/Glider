# Glider

Glider is the logger for just about everything; *it's like [winston.js](https://github.com/winstonjs/winston) but for for mobile!*

**Glider is designed to be a simple, performant, universal logging library supporting multiple transports.**  
A transport is essentially a storage device for your logs.  

Each logger can have multiple transports configured at different levels; you can also customize how the messages are formatted.

# Why Logging?

Logging and monitoring are fundamental parts of our job as engineers.  
Especially in mobile world (with very heterogeneous environments), you'll often find yourself in a situation where understanding how your software behaves in production is essential.

That's the right job for logging: logged data provide valuable information that would be difficult to gather otherwise, unveil unexpected behaviors and bugs, and even if the data was adequately anonymized, identify the sequences of actions of singular users.

# Feature Highlights

We loved making this open-source package and would see engineers like you using this software.  
Those are 5 reasons you will love Glider:

- 🧩 14+ built-in, fully customizable transports to store your data ([ELK](https://github.com/malcommac/Glider/tree/main/GliderELK/Sources), [HTTP](https://github.com/malcommac/Glider/blob/main/Glider/Sources/Transports/HTTPTransport/HTTPTransport.swift), [Logstash](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Transports/LogstashTransport), [SQLite](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Transports/SQLiteTransport), [WebSocket](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Transports/WebSocketTransport), [Console](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Transports/Console), [File/Rotating Files](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Transports/File), [POSIX](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Transports/File/POSIXTransports), [swift-log](https://github.com/malcommac/Glider/tree/main/GliderSwiftLog/Sources), [sentry.io](https://github.com/malcommac/Glider/tree/main/GliderSentry/Sources)...)
- ✏️ 7+ customizable formatters for log messages ([JSON](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Formatters/JSONFormatter), [Fields based](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Formatters/FieldsFormatter)), [MsgPack](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Formatters/MsgPackFormatter), [Syslog](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Formatters/SysLogFormatter))...)
- 🚀 A simple APIs set with an extensible architecture to suit your need
- 📚 A fully documented code (check out our DoCC site!)
- ⚙️ An extensive unit test suite
  
# One Line Implementation

Creating a logger is simple.  
Each logger is an instance of `Log` class; typically, you need to specify one or more transports (where the data is stored).

```swift
let logger = Log {
 $0.subsystem = "com.my-awesome-app"
 $0.category = "ui-events"
 $0.level = .info
 $0.transports = [ConsoleTransport()]
}
```

The following logger shows received messages - only warning or more severe - in the console.

```swift
// Logs an error (including stack trace)
logger.error?.write("Unexpected error has occurred!", 
                    extra: ["reason": error.localizedDescription, "info": extraInfoDict])

logger.info?.write { // Logs an event with a set of attached details
  $0.message = "User tapped Buy button"
  $0.object = encodableProduct
  $0.extra = ["price": price, "currency": currency]
  $0.tags = ["productId", pID]
}
```

# APIs Documentation

APIs are fully documented using Apple DoCC.  
Click here to read it.
# Guide

The following manual will guide you through the usage of Glider for your project.
## Introduction

- [The Logger](./Documentation/Logger.md#the-logger)
- [Writing messages](./Documentation/Logger.md#writing-messages)
  - [Writing simple messages](./Documentation/Logger.md#writing-simple-messages)
  - [Writing messages using closures](./Documentation/Logger.md#writing-messages-using-closures)
  - [Writing message by passing `Event`](./Documentation/Logger.md#writing-message-by-passing-event)
- [Message text composition](./Documentation/Logger.md#message-text-composition)
- [Disabling a Logger](./Documentation/Logger.md#disabling-a-logger)
- [Severity Levels](#severity-levels)
- [Synchronous and Asynchronous Logging](./Documentation/Logger.md#synchronous-and-asynchronous-logging)
  - [Synchronous Logging](./Documentation/Logger.md#synchronous-logging)
  - [Asynchronous Logging](./Documentation/Logger.md#asynchronous-logging)

## Event Formatters

- [Formatters](./Documentation/Formatters.md#formatters)
- [Archiving](./Documentation/Formatters.md#archiving)
  - [FieldsFormatter](./Documentation/Formatters.md#fieldsformatter)
  - [JSONFormatter](./Documentation/Formatters.md#jsonformatter)
  - [MsgPackDataFormatter](./Documentation/Formatters.md#msgpackdataformatter)
- [User Display (Console/Terminals)](./Documentation/Formatters.md#user-display-consoleterminals)
  - [TableFormatter](./Documentation/Formatters.md#tableformatter)
  - [TerminalFormatter](./Documentation/Formatters.md#terminalformatter)
  - [XCodeFormatter](./Documentation/Formatters.md#xcodeformatter)
  - [SysLogFormatter](./Documentation/Formatters.md#syslogformatter)

## Data Transports

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

`NetWatcher` package offers the ability to capture the network traffic of your app (including requests/responses) and redirect them to a specific transport.  
It's fully integrated with Glider and absolutely simple to use.

- [Network Sniffer](./Documentation/NetWatcher.md#network-sniffer)
  - [Introduction](./Documentation/NetWatcher.md#introduction)
  - [Installation](./Documentation/NetWatcher.md#installation)
  - [Capture Taffic](./Documentation/NetWatcher.md#capture-taffic)
    - [NetWatcherDelegate](./Documentation/NetWatcher.md#netwatcherdelegate)
  - [Transports](./Documentation/NetWatcher.md#transports)
    - [NetSparseFilesTransport](./Documentation/NetWatcher.md#netsparsefilestransport)
    - [NetArchiveTransport](./Documentation/NetWatcher.md#netarchivetransport)

# Help Us!

If you want to join this project we're maintaining a list of new features we would to implement into the next versions of Glider. 
Open an issue and discuss one of them with us!

- [ ] GliderViewer: a macOS, iPad & iPhone app to view and interact with logged data
- [ ] New Transports: we would like to extend the list of supported transports; feel free to propose your third party transports
- [ ] Increment our code coverage by writing more tests

# Installation

## Swift Package Manager

The Swift Package Manager is a tool for automating the distribution of Swift code and is integrated into the swift compiler. It is in early development, but Glider does support its use on supported platforms.

Once you have your Swift package set up, adding Willow as a dependency is as easy as adding it to the dependencies value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/malcommac/Glider.git")
]
```

Manifest also includes third-party packages for additional transports, like ELK or Sentry.  
The Glider core SDK is `Glider` package.

## CocoaPods

CocoaPods is a dependency manager for Cocoa projects.  
To integrate Glider into your project, specify it in your Podfile:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

pod 'GliderLogger'
```

## Powered Apps

Glider was created by the amazing mobile team at [ImmobiliareLabs](http://labs.immobiliare.it), the Tech dept at Immobiliare.it.
We are currently using Glider for logging in all of our products.

**If you are using Glider in your app [drop us a message](mailto:mobile@immobiliare.it), we'll add below**.

<a href="https://apps.apple.com/us/app/immobiiiare-it-indomio/id335948517"><img src="./Documentation/assets/immobiliare-app.png" alt="Indomio" width="270"/></a>

## Support & Contribute

Made with ❤️ by [ImmobiliareLabs](https://github.com/orgs/immobiliare) & [Contributors](https://github.com/immobiliare/Glider/graphs/contributors)

We'd love for you to contribute to Glider!  
If you have any questions on how to use Glider, bugs and enhancement please feel free to reach out by opening a [GitHub Issue](https://github.com/immobiliare/Glider/issues).
