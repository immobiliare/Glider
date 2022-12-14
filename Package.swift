// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Glider",
    platforms: [
        .iOS(.v10), .macOS(.v10_14), .tvOS(.v12)
    ],
    products: [
        .library(name: "Glider", targets: ["Glider"])
    ],
    dependencies: [],
    targets: [
        .systemLibrary(
            name: "CSQLiteGlider",
            providers: [.apt(["libsqlite3-dev"])]
        ),
        .target(
            name: "Glider",
            dependencies: ["CSQLiteGlider"],
            path: "Glider/Sources"
        ),
        .testTarget(
            name: "GliderTests",
            dependencies: [
                "Glider"
            ],
            path: "Tests/GliderTests"
        )
    ]
)
