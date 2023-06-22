// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftRapidJSON",
    products: [
      .library(name: "SwiftRapidJSON",
               targets: ["SwiftRapidJSON"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SwiftRapidJSON",
            dependencies: [],
            path: "Sources/SwiftRapidJSON",
            cxxSettings: [
              .headerSearchPath("../../rapidjson/include")])
    ]
)
