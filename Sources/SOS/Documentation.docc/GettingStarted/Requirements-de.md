# Systemanforderungen

Welches System nutze ich?

## Systemkonfiguration

- Apple Silicone M2
  - Tahoe
  - zsh
- homebrew
  - qemu
- (Embedded) Swift 6.2 von **Swiftly**
  ```bash
  $swift --version
  Apple Swift version 6.2.3 (swift-6.2.3-RELEASE)
  Target: arm64-apple-macosx26.0
  Build config: +assertions
  ```
  - Swift Package Manager
- clang
  ```bash
  $clang --version                           
  Apple clang version 17.0.0 (https://github.com/swiftlang/llvm-project.git f403f1080b28ed3bf592ccbc491dadda2a5d4814)
  Target: arm64-apple-darwin25.3.0
  Thread model: posix
  InstalledDir: ~/Library/Developer/Toolchains/swift-6.2-RELEASE.xctoolchain/usr/bin
  Build config: +assertions
  ```
- git
- Xcode (als Editor)

**Hinweis:** Der [Swift Package Index](https://swiftpackageindex.com/bastie/SOS) baut diese Projekt erfolgreich unter Linux.
