// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Glider",
    platforms: [
        .iOS(.v13), .macOS(.v12), .watchOS(.v5), .tvOS(.v13)
    ],
    products: [
        .library(name: "Glider", targets: ["Glider"]),
        .library(name: "GliderSwiftLog", targets: ["GliderSwiftLog"]),
        .library(name: "GliderELK", targets: ["GliderELK"]),
        .library(name: "GliderSentry", targets: ["GliderSentry"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
        .package(url: "https://github.com/swift-server/async-http-client.git", .upToNextMinor(from: "1.5.0")),
        .package(url: "https://github.com/getsentry/sentry-cocoa.git", .upToNextMinor(from: "7.17.0"))
    ],
    targets: [
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
            name: "GliderSentry",
            dependencies: [
                "Glider",
                .product(name: "Sentry", package: "sentry-cocoa")
            ],
            path:"GliderSentry/Sources"
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
            name: "GliderSentryTests",
            dependencies: [
                "Glider",
                "GliderSentry"
            ],
            path: "Tests/GliderSentryTests"
        )
    ]
)
