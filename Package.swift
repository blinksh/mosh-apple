// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "mosh-apple",
  platforms: [.macOS("11")],
  dependencies: [
    .package(url: "https://github.com/blinksh/FMake", from : "0.0.16"),
    // .package(path: "../FMake")
  ],
  targets: [
    .binaryTarget(
        name: "Protobuf_C_",
        url: "https://github.com/blinksh/protobuf-apple/releases/download/v3.21.1/Protobuf_C_-static.xcframework.zip",
        checksum: "a74e23890cf2093047544e18e999f493cf90be42a0ebd1bf5d4c0252d7cf377a"
    ),
    .target(
      name: "build",
      dependencies: ["FMake"]),
  ]
)
