// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Yutools",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "Yutools", targets: ["AndroidToolbox"])
    ],
    targets: [
        .executableTarget(
            name: "AndroidToolbox",
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "AndroidToolboxTests",
            dependencies: ["AndroidToolbox"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
