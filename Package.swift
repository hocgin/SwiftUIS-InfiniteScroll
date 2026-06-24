// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build the package.

import PackageDescription

let package = Package(
    name: "SwiftUIS-InfiniteScroll",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "SwiftUIS-InfiniteScrollWithDay",
            targets: ["SwiftUIS-InfiniteScrollWithDay"]
        ),
        .library(
            name: "SwiftUIS-InfiniteScrollWithDate",
            targets: ["SwiftUIS-InfiniteScrollWithDate"]
        ),
        .library(
            name: "SwiftUIS-InfiniteScroll",
            targets: ["SwiftUIS-InfiniteScroll"]
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
        .target(
            name: "SwiftUIS-InfiniteScrollWithDate",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "SwiftUIS-InfiniteScrollWithDateTests",
            dependencies: ["SwiftUIS-InfiniteScrollWithDate"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "SwiftUIS-InfiniteScroll",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "SwiftUIS-InfiniteScrollTests",
            dependencies: ["SwiftUIS-InfiniteScroll"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
