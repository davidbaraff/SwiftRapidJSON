// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftRapidJSON",
    products: [
      .library(name: "SwiftRapidJSON",
               targets: ["SwiftRapidJSONCxx", "SwiftRapidJSON"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SwiftRapidJSON",
            dependencies: ["SwiftRapidJSONCxx"]),
        .target(
            name: "SwiftRapidJSONCxx",
            dependencies: [],
            path: "Sources/SwiftRapidJSONCxx",
            cxxSettings: [
              .headerSearchPath("../../rapidjson/include")])
    ],
    cxxLanguageStandard: .cxx17
)
