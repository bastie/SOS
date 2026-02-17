// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

/// In ARM64 (AArch64) programming, this hvc (Hypervisor Call) instruction is used to request services of the hypervisor (Exception Level 2) from a lower level (usually EL1, the operating system kernel).
@_extern(c, "arm_hvc_call")
func armServiceOnExceptionLevel2(_ functionID: UInt32)

/// This is a helper funktion (hint) for LLVM to DO NOT inline functions
@_silgen_name("llvm.sideeffect")
func llvmSideEffect()

/// This is our **Swift** Kernel, called by boot process
@_silgen_name("kmain")
public func main(dtbPointer: UInt64,              // x0: adresse of Device Tree Blob
                 _ reserved1: UInt64,             // x1: Reserviert (0)
                 _ reserved2: UInt64,             // x2: Reserviert (0)
                 _ reserved3: UInt64              // x3: Reserviert (0)
) {
  // write SOS from Swift to see this parts run correctly - debuging is for loosers
  let output = StaticString(stringLiteral: " SOS Kernel\n")
  print(content: output)
  
  if 0 != dtbPointer{
    // Dann erst als Pointer interpretieren
    let ptr = UnsafeRawPointer(bitPattern: UInt(dtbPointer))!
    // Verifizierung der Magic Number (Big Endian 0xd00dfeed)
    let magic = ptr.load(as: UInt32.self).byteSwapped
    if magic == 0xd00dfeed {
      // Device Tree Header with magic value detected
      print (content: "Device Tree found\n")
    }
    else {
      print (content: "ERROR: DTB magic value not found\n")
    }
  }
  else {
    print(content: "WARN: DTB not initialize\n")
  }
  
  // 🎶 Bye, bye baby - baby bye 🎶
  print (content: "Shutdown system!\n")
  PowerAction.perform(.shutdown)
}

/// The Output type safe declaration
enum OutputTarget {
  // UART output
  case UART
}

/// Print the `content` to the OutputTarget
/// - Parameters:
///   - content the string literal to print
///   - to the output stream
@inline(__always)
func print(content : StaticString, to : OutputTarget = .UART) {
  // content is a 0x0 terminated string like C
  // like C we iterate over the bytes until the 0x0 tells us we are at end
  var pointerToNextByte = content.utf8Start
  var isStringEndReached = pointerToNextByte.pointee != 0x0
  while isStringEndReached {
    let nextByte = pointerToNextByte.pointee
    writeUART(nextByte)
    
    pointerToNextByte = pointerToNextByte.successor()
    isStringEndReached = pointerToNextByte.pointee != 0x0
  }
}

/// This function write a single byte to the UART output
/// - Parameter byte to write on UART
@inline(__always)
func writeUART(_ byte: UInt8) {
  let uartBase: UInt = 0x09000000
  let dataReg = UnsafeMutableRawPointer(bitPattern: uartBase)!
  let flagReg = UnsafeMutableRawPointer(bitPattern: uartBase + 0x18)!
  
  while true {
    let flags = flagReg.load(as: UInt32.self)
    llvmSideEffect() // 📢 Hey LLVM, do not make an optimize with delete my kernel
    if (flags & 0x20) == 0 {
      break
    }
  }
  
  // writes byte
  dataReg.storeBytes(of: UInt32(byte), toByteOffset: 0, as: UInt32.self)
  llvmSideEffect() // 📢 Hey LLVM, do not make an optimize with delete my kernel
}



// type safe hardware controlling
enum PowerAction: UInt32 {
  // shutdown our system
  case shutdown = 0x84000008
  // reset our system
  case reset    = 0x84000009
}

extension PowerAction {
  /// Type-save function to perform an `PowerAction`
  /// - Parameter action to perform
  static func perform(_ action: PowerAction) {
    // from Kernel we need to ask ARM exception level 2 (hypervisor) do power management functions
    armServiceOnExceptionLevel2 (action.rawValue)
  }
}
