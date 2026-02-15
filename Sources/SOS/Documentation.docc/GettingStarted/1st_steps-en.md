# 1st steps

How to start with this project?

## Set up the project

See <doc:Requirements-en> and check the system requirements.

Clone this project local, goto to the directory and switch to branch `BareMetal`. Now execute the shell script`makeOS.sh`.



```bash
$ git clone https://github.com/bastie/SOS.git
Klone nach 'SOS'...
remote: Enumerating objects: 15, done.
remote: Counting objects: 100% (15/15), done.
remote: Compressing objects: 100% (13/13), done.
remote: Total 15 (delta 0), reused 15 (delta 0), pack-reused 0 (from 0)
Empfange Objekte: 100% (15/15), 5.74 KiB | 5.74 MiB/s, fertig.

$ cd SOS

$ git switch BareMetal
Branch 'BareMetal' folgt nun 'origin/BareMetal'.
Zu neuem Branch 'BareMetal' gewechselt

$ ./makeOS.sh 
STEP 1: compile Swift kernel...
Building for production...
/Users/bastie/Documents/workspace/temp/SOS/Sources/Kernel/RuntimeSupport.swift:21:2: warning: symbol name 'free' is reserved for the Swift runtime and cannot be directly referenced without causing unpredictable behavior; this will become an error
19 | 
20 | // Bad future bug is "Symbol name 'free' is reserved for the Swift runtime and cannot be directly referenced without causing unpredictable behavior; this will become an error"
21 | @_cdecl("free")
|  `- warning: symbol name 'free' is reserved for the Swift runtime and cannot be directly referenced without causing unpredictable behavior; this will become an error
22 | public func free(_ ptr: UnsafeMutableRawPointer?) {
23 |   // at this moment wie dont have something todo

Build complete! (0.45s)
STEP 2: compile Assembler bridge...
STEP 3: link all together ...
STEP 4: start QEMU...
Boot SOS Kernel
Shutdown system!

$
```

### Result

If display ends with output `Boot SOS Kernel` and `Shutdown system!`,  **your system is correct** initialized. 

*What do`makeOS.sh`?*

0. **The Target Platform**: Every operating system is essentially a program that runs in bare metal. For SOS to behave as bare metal, it will use the triple `aarch64-none-none-elf` for our ARM64, as we need the *ELF* format. This triple is fundamental and implemented in various places.
1. **Embedded Swift**: This script first compiles the Swift source code in embedded mode using SPM.
2. **Assembler**: Unfortunately, it's not entirely possible to do without assembly (until I have more time for that), and the script also compiles the necessary assembly source code.
3. **Linking**: Unfamiliar to high-level language developers, the object files are now linked. We're essentially finished now.
4. **Testing**: To test, we now start our SOS (composed of assembly and Swift) with `qemu`. As a result, we see three outputs, since we enabled UART.

    0. The output `Boot` comes from the assembler. This tells us that our assembly part was executed successfully.
    1. The output `SOS Kernel` comes from Embedded Swift. This means that the assembler successfully transferred control to Swift, and we were able to send outputs from Swift to UART.
    2. The output `Shutdown system!` – actually, this means that we are now back in our shell and not remaining in `qemu`. This shows that we were able to trigger the shutdown from Swift in a type-safe manner. This also means that we were able to call our assembler from Swift (unfortunately still necessary here).

However, we must note that we are still completely within the Qemu environment, and this is still hardcoded. But this is a task that shouldn't be addressed here.

## Next Steps

You can now switch back to the `main` branch and dive into your project – Good luck!
