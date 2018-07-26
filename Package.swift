// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MPQArchive",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "MPQArchive",
            targets: ["MPQArchive"]),
        .executable(
            name: "swiftmpq",
            targets: ["swiftmpq"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
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
