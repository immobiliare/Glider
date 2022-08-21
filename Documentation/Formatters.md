# Formatters

- [Formatters](#formatters)
- [Archiviation](#archiviation)
  - [FieldsFormatter](#fieldsformatter)
  - [JSONFormatter](#jsonformatter)
  - [MsgPackDataFormatter](#msgpackdataformatter)
- [User Display (Console/Terminals)](#user-display-consoleterminals)
  - [TableFormatter](#tableformatter)
  - [TerminalFormatter](#terminalformatter)
  - [XCodeFormatter](#xcodeformatter)
  - [SysLogFormatter](#syslogformatter)

When you send a log `Event` to a logger, and therefore to a specified transport, the event should be transformed in a textual or binary representation.  
The `EventMessageFormatter` protocol is consulted when attempting to convert an event into a string; its implementation is very simple:

```swift
public protocol EventMessageFormatter {
    func format(event: Event) -> SerializableData?   
}
```

`format(event:)` function is responsible to convert an event to `SerializableData` which can be `Data` or `String`, depending the type of output you wanna get.

The vast majority of transports offers, in their configuration, a property called `formatters`: you can specify one or more formatters that will be executed in order and contribute to transform the output at each step.  
Typically you are done specifyng a single formatter which define the output of the event for a particular transport instance.  

# Archiviation

Glider offers several different event formatters, some suitable for console display, some other suggested for archiviation.
## FieldsFormatter

The `FieldsFormatter` provides a simple interface for constructing a customized `EventMessageFormatter` by specifying different fields along with their visual representation.

Let’s say you wanted to construct a formatters that outputs the following fields separated by tabs:

- The event's timestamp property as a ISO8601 time value
- The severity of the event as a numeric value
- The message attached to the event (tail truncated to 200 chars)

You could do this by constructing a `FieldsFormatter` as follows:

```swift
let myFormatter = FieldsFormatter(fields: [
    .timestamp(style: .iso8601),
    .level(style: .numeric),
    .message( {
         $0.truncate = .tail(length: 200)
         $0.stringFormat = "Message [%@]"
    }
])

let consoleTransport = ConsoleTransport {
    $0.formatters = [myFormatter]
}

let logger = Log {
    $0.transports = ConsoleTransport
}
```

You can fully customize the format; there are [20+ different event properties](https://github.com/malcommac/Glider/blob/main/Glider/Sources/Formatters/FieldsFormatter/FieldsFormatter%2BField.swift) you can use for your formatted messages; for each property you can also customize how it's visually presented by setting the following properties:

- `truncate`: truncate the output with 3 modes (lead, middle and trail) at a specified length
- `padding`: pad the output by aligning it on left, center and right
- `transforms`: specify one or more function to transform the String
- `colors`: with supported formatters (by default `TerminalFormatter` with ANSII compatible terminals, and `XCodeFormatter` with an hack) you can specify the color attributes of the text
- `format`: how complex properties of an event should be encoded (`extra`, `tags`, `object` or `user`)
- `stringFormat`: specify how to decorate the output via string formatting


## JSONFormatter

The `JSONFormatter` formatter is used to write events data by using the JSON file format.

> **Note**
> Not all properties are expressible in JSON.
> For example event's `object` cannot be serialized. If you want to add it to formatter's `field` to store you must set `encodeDataAsBase64 = true`.
> Data will be encoded using Base64 which means a sensible increment of the final payload size.
> Consider using other formats when you deal with binary data (`MessagePack`](https://msgpack.org/index.html) with `MsgPackFormatter` for example).

This formatter is similar to the `FieldFormatter`; you should specify fields to include into the payload and eventually the JSON encoding options.

```swift
let fileTransport = try FileTransport(fileURL: fileURL, {
    // Using the `standard` format it will serialize level, message, extra and tags-
    $0.formatters = [JSONFormatter.standard()]
})
```

In this example we want to customize the fields used into the payload:

```swift
let customJSONFormatter = JSONFormatter(
    jsonOptions: [],
    encodeDataAsBase64: true, // used to encode object
    fields: [
        .timestamp(style: .iso8601),
        .level(style: .numeric),
        .message(),
        .object(),
        .extra(keys: nil),
        .tags(keys: nil)
    ])
```

## MsgPackDataFormatter

The `MsgPackDataFormatter` allows to store `Event` data using the [`MessagePack`](https://msgpack.org/index.html) file format which produce a compact (and faster to read) representation of the data compared to other formats like JSON.  

> **Note**
> Since MsgPack is a binary format we suggest using it when you need to store data you will read with another program.

The `MsgPackDataFormatter.standard()` configuration encode automatically `timestamp`, `level`, `message`, `objectMetadata`, `object`, `extra` and `tags`.  
You can still customize it by passing your own list of `fields`:

```swift
let msgPackCustomFormatter = MsgPackFormatter(fields: [
    .callSite(),
    .message(),
    .category(),
    .subsystem(),
    .fingerprint()
])
```
# User Display (Console/Terminals)

## TableFormatter

`TableFormatter` is used to format log messages for console display by presenting data with an ASCII table.
This is useful when you need to print complex data using tables rendered via console.

## TerminalFormatter

This formatter is used to print log into terminals or `stdout`/`stderr`.  
It also support colors and styles where the output supports ANSI escape codes for colors and styles.  
By default the formatted fields include an ISO8601 timestamp, the level and the message.  

## XCodeFormatter

The`XCodeFormatter` is used to print messages directly on XCode debug console.  
It mimics the typical structure of debug messages and also add colorization to the output.

While XCode console does not support colorization anymore you can still use an hack to show them. Take a look at `colorize` property for more informations.

## SysLogFormatter

This formatter is used to produce a log in standard [RFC5424](https://datatracker.ietf.org/doc/html/rfc5424).  
The message is composed of three parts: the header, the structured data part and the named message.

- header (priority, version, timestamp, host, application, pid, message id)
- structured data - section with square brackets
- message

For example:

`<priority>VERSION ISOTIMESTAMP HOSTNAME APPLICATION PID MESSAGEID [STRUCTURED-DATA] MESSAGE`

> **Note**
> Sys-log formatter does not log `Scope`.

```swift
let sysLogFormatter = SysLogFormatter(hostname: "myawesomeapp", extraFields: [.callingThread(style: .integer), .eventUUID()])
```
