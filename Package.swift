// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ValleytainmentFCPAI",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "FCPAIKit", targets: ["FCPAIKit"]),
        .executable(name: "fcp-ai-cli", targets: ["FCPAIHostCLI"])
    ],
    targets: [
        .target(
            name: "FCPAIKit",
            path: "Sources/FCPAIKit"
        ),
        .executableTarget(
            name: "FCPAIHostCLI",
            dependencies: ["FCPAIKit"],
            path: "Sources/FCPAIHostCLI"
        ),
        .testTarget(
            name: "FCPAIKitTests",
            dependencies: ["FCPAIKit"],
            path: "Tests/FCPAIKitTests"
        )
    ]
)
