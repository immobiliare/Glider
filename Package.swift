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
        .library(name: "GliderELK", targets: ["GliderELK"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
        .package(url: "https://github.com/swift-server/async-http-client.git", .upToNextMinor(from: "1.5.0"))
    ],
    targets: [
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
        )
    ]
)
