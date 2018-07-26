// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MPQArchive",
    products: [
        .library(
            name: "MPQArchive",
            targets: ["MPQArchive"]),
        .executable(
            name: "swiftmpq",
            targets: ["swiftmpq"]
        )
    ],
    dependencies: [
    
    ],
    targets: [
        .target(
            name: "MPQArchive",
            dependencies: ["libbz2"]),
        .systemLibrary(
            name: "libbz2"
        ),
        .target(
            name: "swiftmpq",
            dependencies: ["MPQArchive"]),
    ]
)
