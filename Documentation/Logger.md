# Logging

- [Logging](#logging)
  - [The Logger](#the-logger)
  - [Writing Messages](#writing-messages)
    - [Simple Write](#simple-write)
    - [Closure Write](#closure-write)
    - [Passing Event](#passing-event)
  - [Severity Levels](#severity-levels)

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

### Simple Write

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

### Closure Write

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

### Passing Event

Finally there are some situation where you need to create an event in a moment and send it later:

```swift
let event = Event(message: "Message #\($0)", extra: ["idx": $0])
// somewhere later
log.info?.write(event: &events)
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

##