// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "mosh-apple",
  platforms: [.macOS("11")],
  dependencies: [
    .package(url: "https://github.com/yury/FMake", from : "0.0.10"),
    // .package(path: "../FMake")
  ],
  targets: [
    .binaryTarget(
        name: "Protobuf_C_",
        url: "https://github.com/yury/protobuf-cpp-apple/releases/download/v3.14.0/Protobuf_C_-static.xcframework.zip",
        checksum: "07433ba7926493200ff7ad31412bc9247d6ddc092b4fa5e650b01c6f36a35559"
    ),
    .target(
      name: "build",
      dependencies: ["FMake"]),
  ]
)
