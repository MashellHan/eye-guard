// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "EyeGuard",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.12.0"),
    ],
    targets: [
        .executableTarget(
            name: "EyeGuard",
            path: "EyeGuard/Sources"
        ),
        .testTarget(
            name: "EyeGuardTests",
            dependencies: [
                "EyeGuard",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "EyeGuard/Tests"
        )
    ]
)
