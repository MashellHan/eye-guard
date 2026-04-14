// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "EyeGuard",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "EyeGuard",
            path: "EyeGuard/Sources"
        ),
        .testTarget(
            name: "EyeGuardTests",
            dependencies: ["EyeGuard"],
            path: "EyeGuard/Tests"
        )
    ]
)
