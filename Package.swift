// swift-tools-version: 6.2

// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

import PackageDescription

// Target we need
let TARGET = "aarch64-none-none-elf"

let package = Package(
  name: "SOS",
  // it works also with .v15 and Swift 6.0 but I have both (Swift 6.2 and macOS Tahoe)
  platforms: [.macOS(.v26)],
  targets: [
    // Swift-only Target
    .target(
      name: "Kernel",
      path: "Sources/Kernel",
      swiftSettings: [
        .enableExperimentalFeature("Embedded"),
        .enableExperimentalFeature("Extern"),
        .enableExperimentalFeature("SymbolLinkageMarkers"),
        .unsafeFlags([
          "-target", TARGET,
          "-wmo",
        ]),
        .unsafeFlags([
          "-Xfrontend", "-disable-stack-protector"
        ]),
        .unsafeFlags([
          "-Xfrontend", "-disable-implicit-concurrency-module-import",
        ]),
      ]
    ),
  ]
)
