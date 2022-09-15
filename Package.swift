// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StackUI",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "StackUI",
            targets: ["StackUI"]
        )
    ],
    dependencies: [
        .package(
            url: "git@github.com:brennobemoura/AssociationKit.git",
            from: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "StackUI",
            dependencies: ["AssociationKit"]
        ),

        .testTarget(
            name: "StackUITests",
            dependencies: ["StackUI"]
        ),
    ]
)
