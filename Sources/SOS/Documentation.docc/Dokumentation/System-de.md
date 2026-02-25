# Systementwicklung

Ein Überblick zur Systemenwicklung

## Topics

- <doc:System-1.0.0+-de>

## Embedded bare-metal Swift

- bleibe auf dem Stack solange bis du Speicher verwalten kannst
  - keine Closures
  - beachte Ausrichtung auf Bytegrenzen auch wenn du Datentypen in `struct`s definierst - manchmal ist ein `UInt64` besser als ein `Bool`
  - keine Klassen
  - nutze `inout` für komplexe Strukturen, da bei großen `struct`s diese auf dem Heap abgeglegt werden könnten 
  - Nutze Tupel oder InlineArray
  - StaticString ist dein Freund (unveränderliche Strings gehen auch)

## Swiftify

### Runtime

Um mit Swift ein Bare Metal System zu erstellen müssen wir einige Funktionen bereitstellen. **Swift ist nicht freestanding**; allerdings ist die minimale Implementierung trivial.    

#### memset
```
@_cdecl("memset")
public func memset(_ s: UnsafeMutableRawPointer, _ c: Int32, _ n: Int) -> UnsafeMutableRawPointer {
```

#### posix_memalign
```
@_cdecl("posix_memalign")
public func posix_memalign(_ memptr: UnsafeMutablePointer<UnsafeMutableRawPointer?>, _ alignment: Int, _ size: Int) -> Int32 {
```

#### free
```
@_cdecl("free")
public func free(_ ptr: UnsafeMutableRawPointer?) {
```

#### arc4random_buf 

```
@_cdecl("arc4random_buf")
public func arc4random_buf(_ buf: UnsafeMutableRawPointer, _ nbytes: Int) {
```

### String

Es ist grundsätzlich der *StaticString* zu bevorzugen. Dieser ist in seiner Größe fest und benötigt daher keinen Heap.

#### putchar

```
@_cdecl("putchar")
public func putchar(_ char: Int32) -> Int32 {
```

Wenn man einen *String* versucht auszugeben, ruft Swift intern die Funktion *putchar* auf und wird in einem reinen Embedded Swift einen Compilerfehler auslösen. Dieses Verhalten ist nicht zu beanstanden, denn Ausgaben im Embedded Bereich sind nicht zwingend.

Durch Bereitstellen der Funktion können wir jedoch eine einfache Unterstützung von print in unserem Embedded Swift erreichen, z.B. um die Ausgaben auf den UART zu leiten.

#### memmove

```
@_cdecl("memmove")
public func memmove(_ dest: UnsafeMutableRawPointer?,
_ src: UnsafeRawPointer?,
_ n: Int) -> UnsafeMutableRawPointer? {
```

String Interpolation kann Swift selbst auf dem Stack für kleine Strings sicher durchführen. Damit dies funktioniert müssen aber die Speicherbereiche an den richtigen Stellen "ineinander kopiert" werden". 

Durch Bereitstellen der Funktion können wir eine einfache String Interpolation von print in unserem Embedded Swift erreichen - aber Achtung bei großen Strings wird unser System sich unerwartet verhalten, weil wir den Stack verlassen und zum Heap wechseln.


## Systemerstellung

Um das System zu erstellen benötigen wir lediglich die [Swift 6 Toolchain](https://www.swift.org/install/macos/), den Clang Compiler und einen Linker. Da wir mehr Integrate-It-Yourself als DIY arbeiten, sind zudem hilfreich der QEMU zur Ausführung, Xcode zur Bearbeitung sowie zsh für Shell-Skripte.
Im Linker ergänzen wir einige Swift-Metainformationen, die wir gern in unserem Kernel behalten wollen. 

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


## Der Bootprozess

Der Bootprozess des AArch64 Rechner beginnt zwingend damit, dass [in das Register x0 die Adresse zum Device Tree]  (https://trustedfirmware-a.readthedocs.io/en/stable/plat/arm/arm_fpga/index.html) gesichert werden muss. Der [Device Tree](https://www.devicetree.org/specifications/) ist eine Struktur, welche unsere Hardware beschreibt. Der Device Tree befindet sich als <div title="Binary Large Object>BLOB</> an der Adresse dort hinterlegten Adresse.
Die AArch64 hat festgelegt, dass im Register x0 der Rückgabewert einer Funktion hinterlegt ist (hier also vereinfacht gesagt der Funktion zur Identifikation der Hardware). AArch64 erlaubt Funktionen [die Register x0 bis x15 ohne Rücksicht zu verwenden](https://developer.arm.com/documentation/102374/0103/Procedure-Call-Standard). Ab dem <div title="Callee-saved Registers">Register x19 bis x28</div> muss hingegen eine Funktion die Inhalte beim Verlassen wieder herstellen, die sie beim Aufruf dort vorfindet. Wir können nur direkt nach dem Aufruf (hier also direkt nach dem Boot) sicher sein, dass sich in dem Register x0 auch die Adresse des Device Tree befindet.
Bevor wir in unseren Swift Kernel springen, müssen wir noch mindestens (und nicht nur) den Stack initialisieren. Daher müssen wir also den Wert aus Register x0 in einen Register x19 bis x28 sichern.
Die Register x0 bis x7 sind zudem als Parameter- und Ergebnis-Register definiert. Implizit werden also bei unserem Aufruf des Kernels diese acht Parameter (meist 8 Adressen) übergeben. Wenn wir unseren gesicherten Wert also wieder nach x0 zurückschreiben ist dieser zugleich der erste Parameter. [Kompatibel mit Linux](https://www.kernel.org/doc/Documentation/arm64/booting.txt) sind wir, wenn wir vier Parameter übergeben. Die anderen drei Parameter sind dabei reserviert.
*Für [RISC-V](https://www.kernel.org/doc/Documentation/riscv/boot.rst) wird hingegen im ersten Parameter die ID der CPU und im zweiten Parameter die Adresse des Device Tree bei Linux erwartet.*

Wir müssen zudem noch beachten, dass viele moderne Systeme mehr als einen Kern haben. Wir schicken also alle anderen Kerne in den Wartemodus und lassen nach dem sichern unseres Zeigers auf den Device Tree Blob nur unseren ersten Kern weiter den Bootprozess durchlaufen. 

## Der Kernel

Der Kernel nimmt als ersten Parameter einen Zeiger für den Devicetree BLOB entgegen. Damit können wir den RAM ermitteln.

Diesen auszuwerten ermöglicht unser System <div title="Position Independent Executable (PIE)">positionsunabhängig</div> in den Speicher zu laden und Zugriff auf die (ersten) Hardwareinformationen zu bekommen.


### Der RAM

Die drei Speicherkategorien im DeviceTree:

```
┌─────────────────────────────────────────────────────┐
│  Physischer RAM (aus /memory Node) - QEMU Beispiel  │
│  0x40000000 ────────────────────────── 0x48000000   │
│                                                     │
│  ┌──────────────────────────────────────────────┐   │
│  │ Memory Reservation Map   (offMemRsvmap)      │   │
│  │ → Firmware, DTB selbst, Secure Monitor       │   │
│  │ → NIEMALS anfassen, auch kein lesen!         │   │
│  └──────────────────────────────────────────────┘   │
│                                                     │
│  ┌──────────────────────────────────────────────┐   │
│  │ /reserved-memory Node                        │   │
│  │ → no-map:  DMA-Puffer, GPU, Secure World     │   │
│  │            physisch exklusiv, kein MMU-Map   │   │
│  │ → reusable: nach Init freigeben möglich      │   │
│  └──────────────────────────────────────────────┘   │
│                                                     │
│  ░░░░░░ Freier RAM für unseren Allocator ░░░░░░░░   │
└─────────────────────────────────────────────────────┘
```

## See Also

- [Tz. 7.3.5.1, Device Tree in x0 beim Boot](https://trustedfirmware-a.readthedocs.io/en/stable/plat/arm/arm_fpga/index.html)
- [Device Tree Spezifikation](https://www.devicetree.org/specifications/)
- [Linux Kernel AArch64 Bootinformationen](https://www.kernel.org/doc/Documentation/arm64/booting.txt)
- [AArch64 Register bei Funktionsaufrufen](https://developer.arm.com/documentation/102374/0103/Procedure-Call-Standard)
- [Arm Base Boot Requirements](https://developer.arm.com/documentation/den0044/latest/)
- [AArch64 Exception Level](https://developer.arm.com/documentation/100069/0606/Overview-of-AArch64-state/Exception-levels?lang=en)
