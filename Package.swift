// swift-tools-version: 6.0

import Foundation
import PackageDescription

let infoPlistPath = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("Info.plist")
    .path

let package = Package(
    name: "apple-calendar-cli",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "apple-calendar-cli",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            linkerSettings: [
                .linkedFramework("EventKit"),
                // A standalone CLI needs its privacy usage strings embedded in the Mach-O binary.
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", infoPlistPath,
                ]),
            ]
        ),
        .testTarget(
            name: "apple-calendar-cli-tests",
            dependencies: ["apple-calendar-cli"],
            linkerSettings: [
                .linkedFramework("EventKit"),
            ]
        ),
    ]
)
