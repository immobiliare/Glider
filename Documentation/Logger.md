# Logging

- [Logging](#logging)
  - [The Logger](#the-logger)
  - [Writing Messages](#writing-messages)
    - [Write Simple Message](#write-simple-message)
    - [Write with Closure](#write-with-closure)
    - [Write by passing Event](#write-by-passing-event)
  - [Creating a Message](#creating-a-message)
  - [Disabling a Logger](#disabling-a-logger)
  - [Severity Levels](#severity-levels)
  - [Synchronous and Asynchronous Logging](#synchronous-and-asynchronous-logging)
    - [Synchronous Logging](#synchronous-logging)
    - [Asynchronous Logging](#asynchronous-logging)

## The Logger

Logging is done via a `Log` instance.  
Depending the architecture/complexity of your application you may have a single or multiple logger instances, each one with their own settings.

The best way to create a log instance is to use the initialization via configuration callback:

```swift
let logger = Log {
    $0.subsystem = "com.indomio.analytics"
    $0.category = "mixpanel"
    $0.level = .info
    $0.transports = [
        ConsoleTransport(...),
        SQLiteTransport(...)
    ]
}
```

`Configuration` object, passed inside the callback param, allows you to configure different aspect of the logger's behaviour. For example:

- `subsystem` and `category`: used to identify a logger specifing the main package and 
- `level` set the minimum severity level accepted by the log (any message with a lower severity received by the logger is automatically discarded).
- `transports` defines one or more destinations for received messages. A transport can save your messages in a local file, a database or send it remotely to a web-service like the ELK stacks or Sentry.io.
- `isEnabled`: when `false` any message received by the log is ignored. It's useful to temporary disable reception of data.
- `isSynchronous`: Identify how the messages must be handled when sent to the logger instance. Typically you want to set if to `false` in production and `true` in development.

## Writing Messages

Sending a message to a logger is pretty simple; simply append the severity level channel to your logger instance and call `write()` function:

```swift
logger.error?.write(msg: "Something bad has occurred")
logger.trace?.write(msg: "User tapped buy button for item \(item.id)")
```

> **Warning**
> The first message is accepted by the logger, but the second one is ignored because message's severity level is below the log's set level.

Each event includes `message` but also several other properties used to enrich the context of the message (we'll take a look at `Scope` later below).  
When you write a new message you can also customize the following fields.

- `message`: the message of the event (it can be a literal or interpolated message. Take a look here for more info).
- `object`: you can attach an object to the event (it must be conform to the `SerializableObject` protocol; all simple data types and `Codable` conform object are automatically supported).
- `extra`: you can attach a dictionary of key,value objects to give more context to an event.
- `tags`: tags is another dictionary but some transport may index these values for search (for example `SentryTransport` makes these value searchable inside its dashboard).

Glider's offer different `write()` functions. 

### Write Simple Message

For simple messages you can use the `write(msg:object:extra:tags:)` where the only required parameter is the message of the event. 

> **Note**
> You should use this method when the creation of the text message is silly and fast. If your message is complex and you think it could takes some CPU effort consider using the `write()` function via closure.

```swift
// It generates an info message which includes the details of the operation.
// `extra` fields includes accessory data, while `tags` are indexed values.
logger.info?.write(msg: "User tapped BUY button", 
                   extra: ["qt": quantity, "currency": currency],
                   tags: ["productId": productId])
```

### Write with Closure

Logging a message is easy, but knowing when to add the logic necessary to build a log message and tune it for performance can be a bit tricky. We want to make sure logic is encapsulated and very performant. Glider log level closures allow you to cleanly wrap all the logic to build up the message.

> **Note**
> Glider works exclusively with logging closures to ensure the maximum performance in all situations. Closures defer the execution of all the logic inside the closure until absolutely necessary, including the string evaluation itself. 

In cases where the `Log` instance is disabled or channel is `nil` (severity of message is below `Log` severity), log execution time was reduced by 97% over the traditional log message methods taking a `String` parameter. 
Additionally, the overhead for creating a closure was measured at 1% over the traditional method making it negligible. 

In summary, closures allow Glider to be extremely performant in all situations.

```swift
logger.info?.write {
    $0.message = "User tapped BUY button"
    $0.extra = ["qt": quantity, "currency": currency]
    $0.tags = ["productId": productId]
}
```

This is the best way to write an event and we suggest using it everytime.

### Write by passing Event

Finally there are some situation where you need to create an event in a moment and send it later:

```swift
let event = Event(message: "Message #\($0)", extra: ["idx": $0])
// somewhere later
log.info?.write(event: &events)
```

## Creating a Message

Messages can be simple literals string or may include data coming from variables read at runtime.  
Glider supports privacy and formatting options allow to manage the visibility of values in log messages and how data is presented, as like the Apple's OSLog.  

When you create set a `message` for an event you can specify several attributes for each interpolated value:

- `privacy`: Because users can have access to log messages that your app generates, use the `.private` or `.partialHide` privacy options to hide potentially sensitive information. For example, you might use it to hide or mask an account information or personal data. By default all data is visible in debug, while in production every variable - when not specified - is `private`.
- `pad`: value printed consists of an original value that is padded with leading, middle or trailing characters to a specified total length. The padding character can be a space or a specified character. The resulting string appears to be either right-aligned or left-aligned.
- `trunc`: value is truncated to a max length (lead/trail/middle).

Moreover common data types also support formatting styles.  
For example you can decide how to print `Bool` values (`true/false`, `1/0`, `yes/no`), `Double`, `Int`, `Date` (ISO8601 or custom format) and so on.

Some examples:

```swift
// Strings
logger.info?.write(msg: "Hello \(self.user.fullName), user-id:\(self.user.id, privacy: .private), email:\(self.user.email, privacy: .partiallyHide)") // Hello Mark Ross, user-id:<redacted>, email:hello@dan********

// Boolean
log.info?.write(msg: "Value is \(boolValue, format: .numeric)") // Value is 1/0

// Float as currency
let price = 12.555
log.info?.write(msg: "Price is \(price, format: .currency(symbol: "EUR"))") // Price is 12.5€

// Date
let date = Date()
log.info?.write(msg: "Now is \(date, format: .iso8601)") // Now is 2018-09-12T12:11:00Z

let someLongString = "My long string is not enough to represent anything but it will truncate anyway"
log.alert?.write(msg: "Value is \(someLongString, trunc: .middle(length: 20), privacy: .public)")
// Value is …nyway
```

## Disabling a Logger

The `Log` class has an `isEnabled` property to allow you to completely disable logging. This can be helpful for turning off specific logger objects at the app level, or more commonly to disable logging in a third-party library.

```swift
let logger = Log { ... }
logger.isEnabled = false
// No log messages will get sent to the registered transports

logger.isEnabled = true
// We're back in business...
```

## Severity Levels

Any new message received by a logger is encapsulated in a payload called `Event`; each event has its own severity which allows to identify what kind of data is received (is the event an error? or just a notice?).

Severity of all levels is assumed to be numerically ascending from most important (`emergency`) to least important (`trace`).

Glider uses the [RFC-5424](https://tools.ietf.org/html/rfc5424) standard with 9 different levels for your message (see [this discussion](https://forums.swift.org/t/logging-levels-for-swifts-server-side-logging-apis-and-new-os-log-apis/20365) on Swift Forum).

| Level     | Usage/Description                                                                                                                                                                                                    |
|-----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `emergency` | Application/system is unusable.                                                                                                                                                                                      |
| `alert`     | Action must be taken immediately.                                                                                                                                                                                    |
| `critical`  | Logging at this level or higher could have a significant performance cost.   The logging system may collect and store enough information such as stack shot etc. that may help in debugging these critical errors.   |
| `error`     | Error conditions.                                                                                                                                                                                                    |
| `warning`   | Abnormal conditions that do not prevent the program from completing a specific task.   These are meant to be persisted (unless the system runs out of storage quota).                                                |
| `notice`    | Conditions that are not error conditions, but that may require special handling or that are likely to lead to an error. These messages will be stored by the logging system unless it runs out of the storage quota. |
| `info`      | Informational messages that are not essential for troubleshooting errors.   These can be discarded by the logging system, especially if there are resource constraints.                                              |
| `debug`     | Messages meant to be useful only during development.   This is meant to be disabled in shipping code.                                                                                                                |
| `trace`     | Trace messages.                                                                                                                                                                                                      |

## Synchronous and Asynchronous Logging

Logging can greatly affect the runtime performance of your application or library. Glider makes it very easy to log messages synchronously or asynchronously.  
You can define this behavior when creating the `Configuration` for your `Log` instance.

```swift
let log = Log {
    $0.isSynchronous = false
    // ...configure other parameters
}
```

### Synchronous Logging

Synchronous logging is very helpful when you are developing your application or library. The log operation will be completed before executing the next line of code. This can be very useful when stepping through the debugger. 

The downside is that this can seriously affect performance if logging on the main thread.

> **Note**
> Glider automatically set the `isSynchronous` to `true` on `#DEBUG` and `false` in production.

### Asynchronous Logging

Asynchronous logging should be used for deployment builds of your application or library.  
This will offload the logging operations to a separate dispatch queue that will not affect the performance of the main thread. This allows you to still capture logs in the manner that the Logger is configured, yet not affect the performance of the main thread operations.