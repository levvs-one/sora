// swift-tools-version: 5.9
import PackageDescription

// SoraCore is the shared Swift core for the Apple clients. The targets use
// whole-directory paths on purpose: sibling sub-departments add Config and
// Storage sources under the same directories, and they must be picked up
// without manifest edits.
let package = Package(
    name: "SoraCore",
    products: [
        .library(name: "SoraCore", targets: ["SoraCore"]),
    ],
    targets: [
        .target(name: "SoraCore", path: "Sources/SoraCore"),
        .testTarget(name: "SoraCoreTests", dependencies: ["SoraCore"], path: "Tests/SoraCoreTests"),
    ]
)
