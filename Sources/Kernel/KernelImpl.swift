// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

/// In ARM64 (AArch64) programming, this hvc (Hypervisor Call) instruction is used to request services of the hypervisor (Exception Level 2) from a lower level (usually EL1, the operating system kernel).
@_extern(c, "arm_hvc_call")
func armServiceOnExceptionLevel2(_ functionID: UInt32)

/// This wfi
@_silgen_name("wait_for_interrupt")
func waitForInterrupt()

/// This is a helper funktion (hint) for LLVM to DO NOT inline functions
@_silgen_name("llvm.sideeffect")
func llvmSideEffect()

/// This is our **Swift** Kernel, called by boot process
///
/// - Note Get dtbPointerValue as UInt64 instead of UnsafeRawPointer, because in early kernel programming gets some crazy errors if nil come from Assembler stub. Over an UInt64 value I wrote some temporary debug / test code.
@_silgen_name("kmain")
public func main(dtbPointerValue: UInt64,     // x0: adresse of Device Tree Blob
                 _ reserved1:     UInt64,     // x1: Reserviert (0)
                 _ reserved2:     UInt64,     // x2: Reserviert (0)
                 _ reserved3:     UInt64) {   // x3: Reserviert (0)

  // write SOS from Swift to see this parts run correctly - debuging is for loosers
  let output = StaticString(stringLiteral: " SOS Kernel\n")
  print(content: output)
  
  // check pointer value is not nil
  if 0 != dtbPointerValue {
    // now redefine as pointer
    let ptr = UnsafeRawPointer(bitPattern: UInt(dtbPointerValue))!
    var info : DTBInfo = DTBInfo()
    // parser is nil if no valid magic number can read
    guard var parser = DTBParser(dtbBase: ptr) else {
      // Device Tree Header with invalid magic value detected
      print (content:"DTB invalid!\n")
      while true {
        waitForInterrupt()
      }
    }
    print (content: "Device Tree found\n")
    
    parser.parseDTB(dtbBase: ptr, into: &info)
    print (content: "PARSE DTB erfolgreich\n")
    
    // print first RAM-slot over UART
    if info.memory.offset > 0 {
      print (content: "RAM ")
      let ram = info.memory.region(at: 0)
      print(content: "at adress ")
      if ram.base > UInt32.max {
        printHex64(content: ram.base)
      }
      else {
        printHex32(content: UInt32(ram.base))
      }
      print(content: " size=")
      printDec32(content: UInt32(ram.size / 1024 / 1024))
      print(content: " MB\n")
      
      // → ram.base / ram.size / ram.reservations to build an allocator later
      
      
    }
    else {
      print (content: "INFO: RAM not found - only stack useable!\n")
    }
  }
  else {
    print(content: "WARN: DTB not initialize\n")
  }
  
  // 🎶 Bye, bye baby - baby bye 🎶
  print (content: "Shutdown system!\n")
  PowerActionAArch64.perform(.shutdown)
}


