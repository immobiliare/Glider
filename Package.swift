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
        .library(name: "GliderSwiftLog", targets: ["GliderSwiftLog"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
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
        )
    ]
)
