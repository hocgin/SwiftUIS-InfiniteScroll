// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUIS-InfiniteScrollWithDay",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftUIS-InfiniteScrollWithDay",
            targets: ["SwiftUIS-InfiniteScrollWithDay"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.13.2")),
    ],
    targets: [
        .target(
            name: "SwiftUIS-InfiniteScrollWithDay",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
            ],
            resources: [
                .process("Localizable.xcstrings")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "SwiftUIS-InfiniteScrollWithDayTests",
            dependencies: ["SwiftUIS-InfiniteScrollWithDay"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
