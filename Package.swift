// swift-tools-version:5.1

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
