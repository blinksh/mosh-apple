// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "mosh-apple",
  platforms: [.macOS("11")],
  dependencies: [
    .package(url: "https://github.com/yury/FMake", from : "0.0.16"),
    // .package(path: "../FMake")
  ],
  targets: [
    .binaryTarget(
        name: "Protobuf_C_",
        url: "https://github.com/yury/protobuf-apple/releases/download/v3.14.0/Protobuf_C_-static.xcframework.zip",
        checksum: "a90dbb75b3ef12224d66cddee28073066e0cab6453f79392d8f954b5904b8790"
    ),
    .target(
      name: "build",
      dependencies: ["FMake"]),
  ]
)
