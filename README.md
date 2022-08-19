# Glider

Glider is the logger for just about everything.
You can think Glider as the [winston](https://github.com/winstonjs/winston) for Swift ages!

It was designed to be simple, performant and universal logging library with support multiple transports.  
A transport is essentially a storage device for your logs.  
Each logger can have multiple transports configured at different levels; you can also customize how the message are formatted.

Glider offers a wide set of built-in transports so you just need to plug-and-play it and start logging your app.

# Why Logging?

At Immobiliare, as any other product company, logging and monitoring are fundamental parts of our job as engineers.  
Whether you are a back-end engineer or a front-end one, you'll often find yourself in the situation where understanding how your software behaves in production is important, if not critical.  
This is especially true in mobile world, where you may encounter a wide set of different settings, situations and critical paths.
That's the right job for remote logging: logged data provide valuable information that would be difficult to gather otherwise, unveil unexpected behaviours and bugs, and even if the data was properly anonymized, identify the sequences of actions of singular users.

# What's about apple/swift-log?

Don't worry! Glider is perfectly integrated with Apple's own [swift-log](https://github.com/apple/swift-log) package.  `GliderSwiftLog` package includes the right tool to use `Glider` as backend library.  
To learn more [click here]().

# What you will get?

Creating a logger is really simple.  
Each logger is an instance of `Log` class; typically you need specify one or more transports (where the data is stored).

```swift
let logger = Log {
  $0.subsystem = "com.myawesomeapp"
  $0.category = "storage"
  $0.level = .warning
  $0.transports = [ConsoleTransport()]
}
```

The following logger just show received messages - only warning or more severe - in console.

```swift
logger.error?.write("Unexpected error has occurred!")
```

That's it!

# Why Glider will be your next loggin solution?

We loved making this open source package and we would seen engineers like you using this software.  
Those are 5 reason you will love Glider:

- 🧩 14+ built-in transports to store your data (ELK, HTTP, LogStash, WebSocket, Console, XCode, POSIX...)
- ✏️ 7+ customizable formatters for messages (JSON, Fields, Msg)
- 🚀 A simple APIs set with an extensible architecture to suit your need
- 📚 A fully documented code (check out our DoCC site!)
- ⚙️ An extensive unit test package


