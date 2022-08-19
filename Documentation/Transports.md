# Transports

- [Transports](#transports)
  - [Introduction](#introduction)
  - [Base Transports](#base-transports)
    - [`AsyncTransport`](#asynctransport)

## Introduction

Writing log messages to various locations is an essential feature of any robust logging library.  
This is made possible in Glider through the `Transport` protocol:

```swift
public protocol Transport { 
    var queue: DispatchQueue? { get }
    var isEnabled: Bool { get set }
    var minimumAcceptedLevel: Level? { get set }

    @discardableResult
    func record(event: Event) -> Bool
}
```

- `queue`: represent the `DispatchQueue` used to store events. A serial queue is typically used, such as when the underlying log facility is inherently single-threaded and/or proper message ordering wouldn't be ensured otherwise. However, a concurrent queue may also be used, and might be appropriate when logging to databases or network endpoints. Typically each transport define its own queue and you should never need to modify it.
- `isEnabled`: allows to temporary disable a transport without disabling its parent `Log`.
- `minimumAcceptedLevel`: A filter by `severity` implemented at the transport level. You can, for example, create a logger which logs in `info` but for one of the transport (for example ELK or Sentry) it avoids to send messages with a severity lower than `error` in order to clog your remote service). When `nil` the message is not filtered and all messages accepted by the parent `Log` instance are accepted automatically.

> **Note**
> Moreover most transports also specify another common property called `formatters`.
> A Formatter is an object conform to `EventFormatter` protocol which allows to format the `Event`'s `message` and transform them as you need.  
> For example `ConsoleTransport` defines a single formatter used to print event messages in a style similar to a common XCode print statement (with timestamp, pid, message etc.).

The most important function of the protocol is the `record(event:)` function which receive `Event` instances coming from the parent `Log` instance and implement its own logic to store/send values.

## Base Transports

Glider offers several base transport layers you can use to simplify the creation of your own transport.

### `AsyncTransport`

`AsyncTransport` is a transport specifically made for asynchrouns request.  
It store logs locally in a temporary (in-memory) SQLite3 database; once a specified amount of messages are collected it allows to send them via a network request.

> **Note**
> Typically you don't need to use `AsyncTransport` as is. It powers the `HTTPTransport` transport service.

```swift
// Create the transport
let config = AsyncTransport.Configuration {
    $0.autoFlushInterval = 3
    $0.bufferStorage = .inMemory
    $0.chunksSize = 20
}
let transport = try AsyncTransport(delegate: self, configuration: config)

// The delegate:
public func asyncTransport(_ transport: AsyncTransport,
                               canSendPayloadsChunk chunk: AsyncTransport.Chunk,
                               onCompleteSendTask completion: @escaping ((ChunkCompletionResult) -> Void)) {
    // Send payloads to another network.
}
```

The 