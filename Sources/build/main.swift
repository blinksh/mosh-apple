import FMake
import Foundation

// brew install automake
// brew install libtool

enum Config {
  static let moshOrigin  = "https://github.com/blinksh/mosh.git"
  static let moshSHA     = "5eb502e2373c227f4930d3651fffb15b647c832f"
  static let moshVersion = "1.3.2"
  
  static let frameworkName = "mosh"
}

extension Platform {
  var deploymentTarget: String {
    switch self {
    case .AppleTVOS, .AppleTVSimulator,
         .iPhoneOS, .iPhoneSimulator: return "14.0"
    case .MacOSX, .Catalyst: return "11.0"
    case .WatchOS, .WatchSimulator: return "7.0"
    }
  }
}


OutputLevel.default = .error

// use from `brew install protobuf`

try? sh("rm -rf mosh")
try sh("git clone", Config.moshOrigin)
try cd("mosh") {
  try sh("git reset --hard", Config.moshSHA)
}

let pwd = cwd()
let protobufProtoc = "/usr/local/bin/protoc"
let protobufXCFrameworkPath = "\(pwd)/.build/artifacts/mosh-apple/Protobuf_C_.xcframework"
let moshSrcPath = "\(pwd)/mosh"

let platforms = Platform.allCases // [Platform.iPhoneOS]

extension Platform {
  var protobufPath: String {
    switch self {
    case .AppleTVOS:        return "tvos-arm64"
    case .AppleTVSimulator: return "tvos-arm64_x86_64-simulator"
    case .iPhoneOS:         return "ios-arm64"
    case .iPhoneSimulator:  return "ios-arm64_x86_64-simulator"
    case .WatchOS:          return "watchos-arm64_32"
    case .WatchSimulator:   return "watchos-arm64_x86_64-simulator"
    case .MacOSX:           return "macos-arm64_x86_64"
    case .Catalyst:         return "macos-arm64_x86_64"
    }
  }
  
  var mversionName: String {
    "\(sdk)-version-min"
  }
}

var frameworks: [String] = []

for p in platforms {
  
  let protobufFramewokPath = "\(protobufXCFrameworkPath)/\(p.protobufPath)/Protobuf_C_.framework"
  
  var libs: [String] = []
  
  for arch in p.archs {    
    
    let prefixPath =  "\(pwd)/bin/\(p.name)-\(arch)"
    try sh("rm -rf", prefixPath)
    try sh("mkdir -p", prefixPath)
    try sh("mkdir -p \(prefixPath)/include")
    try sh("mkdir -p \(prefixPath)/lib")
    
    let cflags = "\(p.ccFlags(arch: arch, minVersion: p.deploymentTarget)) -I/usr/local/opt/ncurses/include"
    let cc = try readLine(cmd: "xcrun -find clang")
    
    var env = ProcessInfo.processInfo.environment
    env["ac_cv_path_PROTOC"] = protobufProtoc
    env["protobuf_LIBS"] = "\(protobufFramewokPath)"
    env["protobuf_CFLAGS"] = "-I\(protobufFramewokPath)/Headers"
    env["CC"] = cc
    env["CPP"] = "\(cc) -E"
    env["CFLAGS"] = cflags
    env["CPPFLAGS"] = cflags
    env["AR"] = try readLine(cmd: "xcrun -find ar")
    env["RANLIB"] = try readLine(cmd: "xcrun -find ranlib")    
    env["LDFLAGS"] = "-Wc,-fembed-bitcode -arch \(arch) -isysroot \(try p.sdkPath())"
    // env["LDFLAGS"] = "-arch \"//p.ldFlags(arch: arch, minVersion: p.deploymentTarget)
    
    try cd(moshSrcPath) {
      try sh("./autogen.sh", env: env)
      try sh("./configure --prefix=\(prefixPath)/lib --disable-server --disable-client --enable-ios-controller --host=\(arch)-apple-darwin", env: env)
      try sh("make clean", env: env)
      try sh("make", env: env)
      
      let aFiles = [
        "crypto/libmoshcrypto.a",
        "network/libmoshnetwork.a",
        "protobufs/libmoshprotos.a",
        "statesync/libmoshstatesync.a",
        "terminal/libmoshterminal.a",
        "frontend/libmoshiosclient.a",
        "util/libmoshutil.a"
      ]
      .map { "\(moshSrcPath)/src/\($0)"}
      .joined(separator: " ")
      
      let lib = "\(prefixPath)/lib/libmosh.a"
      libs.append(lib)
      try sh("libtool -static -o", lib, aFiles)
      try sh("cp \(moshSrcPath)/src/frontend/moshiosbridge.h \(prefixPath)/include")
    }
  }
  
  let frameworkPath =  "\(pwd)/frameworks/\(p.name)/\(Config.frameworkName).framework"
  try? sh("rm -rf", frameworkPath)
  try sh("mkdir -p", frameworkPath)
  
  let plist = try p.plist(
    name: Config.frameworkName,
    version: Config.moshVersion,
    id: "org.mosh",
    minSdkVersion: p.deploymentTarget
  )
  
  let moduleMap = p.module(name: Config.frameworkName, headers: .umbrellaDir("."))
  try mkdir("\(frameworkPath)/Headers")
  try sh("cp \(moshSrcPath)/src/frontend/moshiosbridge.h \(frameworkPath)/Headers/")
  try write(content: plist, atPath: "\(frameworkPath)/Info.plist")
  try sh("lipo -create \(libs.joined(separator: " ")) -output \(frameworkPath)/\(Config.frameworkName) ")
  try mkdir("\(frameworkPath)/Modules")
  try write(content: moduleMap, atPath: "\(frameworkPath)/Modules/module.modulemap")
  
  if p == .MacOSX || p == .Catalyst {
    try repackFrameworkToMacOS(at: frameworkPath, name: Config.frameworkName)
  }
  
  frameworks.append(frameworkPath)
}

try cd(".build") {
  let xcframework = "\(Config.frameworkName).xcframework"
  let zip = "\(xcframework).zip"
  try? sh("rm -rf", xcframework)
  try? sh("rm -f", zip)

  try sh(
    "xcodebuild",
    "-create-xcframework",
    frameworks.map { "-framework \($0)" }.joined(separator: " "),
    "-output", xcframework
  )

  try sh("zip --symlinks -r", zip, xcframework)
  let checksum = try sha(path: zip)

  let releaseNotes = 
  """

  Release notes:

  \( [[zip, checksum]].markdown(headers: "File", "SHA 256") )

  """

  try write(content: releaseNotes, atPath: "release.md")
}
