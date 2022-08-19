# Glider

Glider is the logger for just about everything.  
You can think of Glider as the [winston](https://github.com/winstonjs/winston) for Swift ages!

Glider is designed to be a simple, performant, universal logging library supporting multiple transports.  
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

- 🧩 14+ built-in transports to store your data ([ELK](https://github.com/malcommac/Glider/tree/main/GliderELK/Sources), [HTTP](https://github.com/malcommac/Glider/blob/main/Glider/Sources/Transports/HTTPTransport/HTTPTransport.swift), [Logstash](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Transports/LogstashTransport), [SQLite](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Transports/SQLiteTransport), [WebSocket](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Transports/WebSocketTransport), [Console](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Transports/Console), [File](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Transports/File), [POSIX](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Transports/File/POSIXTransports), [Apple's swift-log](https://github.com/malcommac/Glider/tree/main/GliderSwiftLog/Sources)), [Sentry.io](https://github.com/malcommac/Glider/tree/main/GliderSentry/Sources))
- ✏️ 7+ customizable [formatters](https://github.com/malcommac/Glider/tree/main/Glider/Sources/Formatters)) for messages (JSON, Fields, Msg)
- 🚀 A simple APIs set with an extensible architecture to suit your need
- 📚 A fully documented code (check out our DoCC site!)
- ⚙️ An extensive unit test package

# Quickstart
