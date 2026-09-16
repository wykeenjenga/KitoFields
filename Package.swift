// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KitoFields",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "KitoFields", targets: ["KitoFields"])
    ],
    targets: [
        .target(
            name: "KitoFields",
            path: "Sources/KitoFields",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "KitoFieldsTests",
            dependencies: ["KitoFields"],
            path: "Tests/KitoFieldsTests"
        )
    ]
)
