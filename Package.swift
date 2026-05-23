// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AndroidToolbox",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "AndroidToolbox", targets: ["AndroidToolbox"])
    ],
    targets: [
        .executableTarget(
            name: "AndroidToolbox",
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "AndroidToolboxTests",
            dependencies: ["AndroidToolbox"]
        )
    ]
)
