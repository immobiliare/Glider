// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var products: [Product] = [
    .library(name: "Glider", targets: ["Glider"]),
    .library(name: "GliderSwiftLog", targets: ["GliderSwiftLog"]),
    .library(name: "GliderELK", targets: ["GliderELK"]),
    .library(name: "GliderNetWatcher", targets: ["GliderNetWatcher"])
]

var dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
    .package(url: "https://github.com/swift-server/async-http-client.git", .upToNextMinor(from: "1.5.0"))
]

var targets: [Target] = [
    // TARGETS
    .target(
        name: "Glider",
        path: "Glider/Sources"
    ),
    .target(
        name: "GliderSwiftLog",
        dependencies: [
            "Glider",
            .product(name: "Logging", package: "swift-log")
        ],
        path:"GliderSwiftLog/Sources"
    ),
    .target(
        name: "GliderELK",
        dependencies: [
            "Glider",
            .product(name: "AsyncHTTPClient", package: "async-http-client")
        ],
        path:"GliderELK/Sources"
    ),
    .target(
        name: "GliderNetWatcher",
        dependencies: [
            "Glider"
        ],
        path:"GliderNetWatcher/Sources"
    ),

    // TESTS
    .testTarget(
        name: "GliderTests",
        dependencies: [
            "Glider"
        ],
        path: "Tests/GliderTests"
    ),
    .testTarget(
        name: "GliderSwiftLogTests",
        dependencies: [
            "Glider",
            "GliderSwiftLog"
        ],
        path: "Tests/GliderSwiftLogTests"
    ),
    .testTarget(
        name: "GliderELKTests",
        dependencies: [
            "Glider",
            "GliderELK"
        ],
        path: "Tests/GliderELKTests"
    ),

    .testTarget(
        name: "GliderNetWatcherTests",
        dependencies: [
            "Glider",
            "GliderNetWatcher"
        ],
        path: "Tests/GliderNetWatcherTests"
    )
]

// GliderSentry is not available on Linux
#if os(iOS) || os(watchOS) || os(tvOS) || os(macOS)
products.append(.library(name: "GliderSentry", targets: ["GliderSentry"]))
targets.append(contentsOf: [
    .target(
        name: "GliderSentry",
        dependencies: [
            "Glider",
            .product(name: "Sentry",
                     package: "sentry-cocoa",
                     condition: .when(platforms: [.iOS, .macOS, .watchOS, .tvOS]))
        ],
        path:"GliderSentry/Sources"
    ),
    .testTarget(
        name: "GliderSentryTests",
        dependencies: [
            "Glider",
            "GliderSentry"
        ],
        path: "Tests/GliderSentryTests"
    )
])
dependencies.append(.package(url: "https://github.com/getsentry/sentry-cocoa.git", .upToNextMajor(from: "7.0.0")))
#endif


let package = Package(
    name: "Glider",
    platforms: [
        .iOS(.v14), .macOS(.v11), .watchOS(.v7), .tvOS(.v14)
    ],
    products: products,
    dependencies: dependencies,
    targets: targets
)
