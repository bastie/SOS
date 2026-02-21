// swift-tools-version: 6.2

// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

import PackageDescription

// Target we need
let TARGET = "aarch64-none-none-elf"

let package = Package(
  name: "SOS",
  // Hint for you to see the language of pseudo target
  defaultLocalization: "de",
  // it works also with .v15 and Swift 6.0 but I have both (Swift 6.2 and macOS Tahoe)
  // with using of InlineArray instead of Tupel macOS Tahoe is required
  platforms: [.macOS(.v26)],
  dependencies: [
    // other dependencies
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
  ],
  targets: [
    // Swift-only target
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
          "-Xfrontend", "-disable-stack-protector",
          "-Xllvm", "-relocation-model=pic",
        ]),
        .unsafeFlags([
          "-Xfrontend", "-disable-implicit-concurrency-module-import",
        ]),
      ]
    ),
    // Pseudo target to create a documentation
/*START
    .target(
      name: "SOS",
      dependencies: [], // no dependency because no sources
      swiftSettings: [], // overwrite Swift settings
    )
END*/
  ]
)
