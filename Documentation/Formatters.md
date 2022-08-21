# Event Formatters

- [Formatters](#formatters)
- [Suitable for Archiviation](#suitable-![Glider](../../../../Desktop/glider.png)for-archiviation)
  - [FieldsFormatter](#fieldsformatter)
  - [JSONFormatter](#jsonformatter)
  - [MsgPackDataFormatter](#msgpackdataformatter)
- [Suitable for User Display](#suitable-for-user-display)
  - [TableFormatter](#tableformatter)
  - [TerminalFormatter](#terminalformatter)
  - [XCodeFormatter](#xcodeformatter)
  - [SysLogFormatter](#syslogformatter)

When you send a log `Event` to a logger and therefore to a specified transport, the event should be transformed into a textual or binary representation.  
The `EventMessageFormatter` protocol is consulted when attempting to convert an event into a string; its implementation is straightforward:

```swift
public protocol EventMessageFormatter {
    func format(event: Event) -> SerializableData?   
}
```

`format(event:)` function is responsible for converting an event to `SerializableData`, which can be `Data` or `String`, depending on the type of output you want.

The vast majority of transports offer, in their configuration, a property called `formatters`: you can specify one or more formatters that will be executed in order and contribute to transforming the output at each step.  
Typically, you are done specifying a single formatter that defines the event's output for a particular transport instance.  

# Suitable for Archiviation

Glider offers several event formatters, some suitable for console display and others suggested for persistent storage.

## FieldsFormatter

The `FieldsFormatter` provides a simple interface for constructing a customized `EventMessageFormatter` by specifying different fields and their visual representation.

Let’s say you wanted to construct a formatters that outputs the following fields separated by tabs:

- The event's timestamp property as an ISO8601 time value
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

You can fully customize the format; there are [20+ different event properties](https://github.com/malcommac/Glider/blob/main/Glider/Sources/Formatters/FieldsFormatter/FieldsFormatter%2BField.swift) you can use for your formatted messages; for each property, you can also customize how it's visually presented by setting the following properties:

- `truncate`: truncate the output with three modes (lead, middle, and trail) at a specified length
- `padding`: pad the output by aligning it on the left, center, and right
- `transforms`: specify one or more functions to transform the String
- `colors`: with supported formatters (by default, `TerminalFormatter` with ANSII compatible terminals and `XCodeFormatter` with a hack) you can specify the color attributes of the text
- `format`: how complex properties of an event should be encoded (`extra`, `tags`, `object` or `user`)
- `stringFormat`: specify how to decorate the output via string formatting


## JSONFormatter

The `JSONFormatter` formatter is used to write event data by using the JSON file format.

> **Note**
> Not all properties are expressible in JSON.
> For example event's `object` cannot be serialized. If you want to add it to formatter's `field` to store, you must set `encodeDataAsBase64 = true`.
> Data will be encoded using Base64 which means a sensible increment of the final payload size.
> Consider using other formats when you deal with binary data (`MessagePack`](https://msgpack.org/index.html) with `MsgPackFormatter`, for example).

This formatter is similar to the `FieldFormatter`; you should specify fields to include in the payload and eventually the JSON encoding options.

```swift
let fileTransport = try FileTransport(fileURL: fileURL, {
    // Using the `standard` format, it will serialize level, message, extra, and tags-
    $0.formatters = [JSONFormatter.standard()]
})
```

In this example, we want to customize the fields used in the payload:

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

The `MsgPackDataFormatter` allows storing `Event` data using the [`MessagePack`](https://msgpack.org/index.html) file format, which produces a compact (and faster to read) representation of the data compared to other formats like JSON.  

> **Note**
> Since MsgPack is a binary format, we suggest using it when you need to store data you will read with another program.

The `MsgPackDataFormatter.standard()` configuration encode automatically `timestamp`, `level`, `message`, `objectMetadata`, `object`, `extra` and `tags`.  
You can still customize it by passing your list of `fields`:

```swift
let msgPackCustomFormatter = MsgPackFormatter(fields: [
    .callSite(),
    .message(),
    .category(),
    .subsystem(),
    .fingerprint()
])
```
# Suitable for User Display

## TableFormatter

`TableFormatter` is formatted log messages for console display by presenting data with an ASCII table.
This is useful when printing complex data using tables rendered via console.

The following formatter is used to print a tabular version of a network call.

```swift
let tableFormatter = TableFormatter(messageFields: [
	.timestamp(style: .xcode, {
   		$0.padding = .left(columns: 23)
   	),
    .message(),
  ], tableFields: [
     .extra(keys: ["service", "url", "time", "headers", "body", "curl"])
  ])
  tableFormatter.maxColumnWidths = (30, 100)
  $0.console(tableFormatter)
})
```

This is an example of the result:

> **Note**
> Of course, you should use a monospaced font to have the best rendering.

![]()

## TerminalFormatter

This formatter is used to print logs into terminals or `stdout`/`stderr`.  
It also supports colors and styles; the output supports ANSI escape codes for colors and styles.  
The formatted field's default includes an ISO8601 timestamp, the level, and the message.  

## XCodeFormatter

The`XCodeFormatter` is used to print messages directly on XCode debug console.  
It mimics the typical debug message structure and adds colorization to the output.

While the XCode console does not support colorization, you can still use a hack to show them.  

- Add the font file named [ColoredConsole-Bold.ttf](https://github.com/jjrscott/ColoredConsole/blob/master/ColoredConsole-Bold.ttf) via the Mac OS application Font Book.
- Back to Xcode. Go to "Preference" ⇢ "Texts & Colors" ⇢ "Executable console Output", click the font icon below, then set the font to "Colored Console Bold"
- Use the `XCodeFormatter` and set the `colorize` property to add colors to some of the fields

For example:

```swift
let xcodeFormatter = XCodeFormatter {
	// By default, both the `message` and `level` are colorized automatically with a red.
	$0.colorize = .onlyImportant
}
```

> **Note**
> ColoredConsole-Bold is a font based on FiraMono-Bold, which adds ligatures to enable colored messages.

If you need more customization, you can create your own `FieldFormatter` and add colors to the fields.  
The following formatter colorizes the `message` of an event with a yellow text and black background (it works with ANSI Capable Terminals).

```swift
let myFormatter = FieldFormatter(fields: [
	.timestamp(style: .iso8601),
	.literal(" "),
	.level(style: .simple),
	.message({ msgConfig in
	   msgConfig.colors = [ANSITerminalStyles.fg(.yellow), ANSITerminalStyles.bg(.black)]
	})
])
``` variants of the ASCII character set. Take a look at [ColoredConsole](https://github.com/jjrscott/ColoredConsole) repo for more information.

## SysLogFormatter

This formatter produces a log in the standard [RFC5424](https://datatracker.ietf.org/doc/html/rfc5424).  
The message comprises three parts: the header, the structured data, and the named message.

- header (priority, version, timestamp, host, application, PID, message-id)
- structured data - section with square brackets
- message

For example:

`<priority>VERSION ISOTIMESTAMP HOSTNAME APPLICATION PID MESSAGEID [STRUCTURED-DATA] MESSAGE`

> **Note**
> Sys-log formatter does not log `Scope`.

```swift
let sysLogFormatter = SysLogFormatter(hostname: "myawesomeapp", extraFields: [.callingThread(style: .integer), .eventUUID()])
```
