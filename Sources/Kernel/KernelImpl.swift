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
  print(" SOS Kernel")
  
  // check pointer value is not nil
  if 0 != dtbPointerValue {
    // now redefine as pointer
    let ptr = UnsafeRawPointer(bitPattern: UInt(dtbPointerValue))!
    var info : DTBInfo = DTBInfo()
    // parser is nil if no valid magic number can read
    guard var parser = DTBParser(dtbBase: ptr) else {
      // Device Tree Header with invalid magic value detected
      print ("DTB invalid!")
      while true {
        waitForInterrupt()
      }
    }
    print ("Device Tree found")
    
    parser.parseDTB(dtbBase: ptr, into: &info)
    print ("PARSE DTB erfolgreich")

    if let seed = info.chosen.rngSeed {
      initRNGSingleCore(seed: seed, seedLen: info.chosen.rngSeedLen)
      #if DEBUG
      print ("INFO: secure random4arc_buf with ASCON")
      #endif
    }
    else {
      // fallback if DTB provides no rng-seed
      initRNGSingleCore(seed: ptr, seedLen: 8)
    }
    // print first RAM-slot over UART
    if info.memory.offset > 0 {
      let ram = info.memory.region(at: 0)
      print ("RAM at adress 0x", terminator: "")
      print (String (ram.base, radix: 16), terminator: "")
      print(" size=\(UInt32(ram.size / 1024 / 1024)) MB")
      
      // → ram.base / ram.size / ram.reservations to build an allocator later
      
      // TODO: if all cores ran and heap is activated call initRNGMultiCore
      /*
       initRNGMultiCore(count: detectedCoreCount) { size in
         kernelAlloc(size)
       }
       */
      
    }
    else {
      print (content: "INFO: RAM not found - only stack useable!\n")
    }
  }
  else {
    print(content: "WARN: DTB not initialize\n")
  }
  
  // 🎶 Bye, bye baby - baby bye 🎶
  print ("Shutdown system!")
  PowerActionAArch64.perform(.shutdown)
}


