# Logging

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

