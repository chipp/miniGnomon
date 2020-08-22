// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "fix_project",
    dependencies: [
        .package(url: "https://github.com/tuist/XcodeProj", .upToNextMajor(from: "7.14.0"))
    ],
    targets: [
        .target( name: "fix_project", dependencies: ["XcodeProj"]),
    ]
)
