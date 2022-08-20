# Formatters

- [Formatters](#formatters)
- [Built-In Formatters](#built-in-formatters)
  - [FieldsFormatter](#fieldsformatter)

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

# Built-In Formatters

## FieldsFormatter

The `FieldsFormatter` provides a simple interface for constructing a customized `EventMessageFormatter` by specifying different fields along with their visual representation.

Let’s say you wanted to construct a formatters that outputs the following fields separated by tabs:

- The event's timestamp property as a ISO8601 time value
- The severity of the event as a numeric value
- The message attached to the event (tail truncated to 200 chars)

You could do this by constructing a `FieldsFormatter` as follows:

```swift
 let fieldFormatter = FieldsFormatter(fields: [
    .timestamp(style: .iso8601),
    .level(style: .numeric),
    .message( {
         $0.truncate = .tail(length: 200)
    }
])
```

You can fully customize the format; there are [20+ different event properties](https://github.com/malcommac/Glider/blob/main/Glider/Sources/Formatters/FieldsFormatter/FieldsFormatter%2BField.swift) you can use for your formatted messages; for each property you can also customize how it's visually presented by setting the following properties:

- `truncate`: truncate the output with 3 modes (lead, middle and trail) at a specified length
- `padding`: pad the output by aligning it on left, center and right
- `transforms`: specify one or more function to transform the String
- `colors`: with supported formatters (by default `TerminalFormatter` with ANSII compatible terminals, and `XCodeFormatter` with an hack) you can specify the color attributes of the text
- `format`: how complex properties of an event should be encoded (`extra`, `tags`, `object` or `user`)
- `stringFormat`: specify how to decorate the output via string formatting

For example we can sightly 