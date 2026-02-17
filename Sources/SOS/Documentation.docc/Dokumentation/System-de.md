# Systementwicklung

Ein Überblick zur Systemenwicklung

## Topics

- <doc:System-1.0.0+-de>

## Systemerstellung

Um das System zu erstellen benötigen wir lediglich die [Swift 6 Toolchain](https://www.swift.org/install/macos/), den Clang Compiler und einen Linker. Da wir mehr Integrate-It-Yourself als DIY arbeiten, sind zudem hilfreich der QEMU zur Ausführung, Xcode zur Bearbeitung sowie zsh für Shell-Skripte.

Hinweis: Die Nutzung der in Xcode integrierten Toolchain ist nicht ausreichend. Die Installation der Swiftly Toolchain fügt dem Clang weitere notwendige Zielplattformen hinzu.

|ohne Swiftly|mit Swiftly|
|---|---|
|aarch64    - AArch64 (little endian)|aarch64    - AArch64 (little endian)|
|aarch64_32 - AArch64 (little endian ILP32)|aarch64_32 - AArch64 (little endian ILP32)|
|aarch64_be - AArch64 (big endian)|aarch64_be - AArch64 (big endian)|
|arm        - ARM|arm        - ARM|
|arm64      - ARM64 (little endian)|arm64      - ARM64 (little endian)|
|arm64_32   - ARM64 (little endian ILP32)|arm64_32   - ARM64 (little endian ILP32)|
|armeb      - ARM (big endian)|armeb      - ARM (big endian)|
| |avr        - Atmel AVR Microcontroller|
| |mips       - MIPS (32-bit big endian)|
| |mips64     - MIPS (64-bit big endian)|
| |mips64el   - MIPS (64-bit little endian)|
| |mipsel     - MIPS (32-bit little endian)|
| |ppc32le    - PowerPC 32 LE|
| |ppc32      - PowerPC 32|
| |ppc64      - PowerPC 64|
| |ppc64le    - PowerPC 64 LE|
| |riscv32    - 32-bit RISC-V|
| |riscv64    - 64-bit RISC-V|
| |systemz    - SystemZ|
|thumb      - Thumb|thumb      - Thumb|
|thumbeb    - Thumb (big endian)|thumbeb    - Thumb (big endian)|
| |wasm32     - WebAssembly 32-bit|
| |wasm64     - WebAssembly 64-bit|
|x86        - 32-bit X86: Pentium-Pro and above|x86        - 32-bit X86: Pentium-Pro and above|
|x86-64     - 64-bit X86: EM64T and AMD64|x86-64     - 64-bit X86: EM64T and AMD64|



