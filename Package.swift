// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "miniGnomon",
    products: [
        .library(name: "miniGnomon", targets: ["miniGnomon"])
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift", .upToNextMajor(from: "5.1.1")),
        .package(url: "https://github.com/Quick/Nimble", .upToNextMajor(from: "8.0.0"))
    ],
    targets: [
        .target(name: "miniGnomon", dependencies: [
            .product(name: "RxSwift", package: "RxSwift"),
            .product(name: "RxRelay", package: "RxSwift"),
        ]),
        .testTarget(name: "miniGnomonTests", dependencies: [
            "miniGnomon", "Nimble",
            .product(name: "RxBlocking", package: "RxSwift")
        ])
    ]
)
