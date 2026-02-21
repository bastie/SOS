// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

let _HEX_DIGITS: StaticString = "0123456789ABCDEF"

func printHex32(content value: UInt32, to: OutputTarget = .UART) {
  let p = _HEX_DIGITS.utf8Start
  writeUART(48) // 0
  writeUART(120) // x
  writeUART(p[Int((value >> 28) & 0xF)])
  writeUART(p[Int((value >> 24) & 0xF)])
  writeUART(p[Int((value >> 20) & 0xF)])
  writeUART(p[Int((value >> 16) & 0xF)])
  writeUART(p[Int((value >> 12) & 0xF)])
  writeUART(p[Int((value >>  8) & 0xF)])
  writeUART(p[Int((value >>  4) & 0xF)])
  writeUART(p[Int((value >>  0) & 0xF)])
}

func printHex64(content value: UInt64, to: OutputTarget = .UART) {
  writeUART(48) // 0
  writeUART(120) // x
  
  var v = UInt32(value >> 32)
  var p = _HEX_DIGITS.utf8Start
  writeUART(p[Int((v >> 28) & 0xF)])
  writeUART(p[Int((v >> 24) & 0xF)])
  writeUART(p[Int((v >> 20) & 0xF)])
  writeUART(p[Int((v >> 16) & 0xF)])
  writeUART(p[Int((v >> 12) & 0xF)])
  writeUART(p[Int((v >>  8) & 0xF)])
  writeUART(p[Int((v >>  4) & 0xF)])
  writeUART(p[Int((v >>  0) & 0xF)])
  
  v = UInt32(value & 0xFFFF_FFFF)
  p = _HEX_DIGITS.utf8Start
  writeUART(p[Int((v >> 28) & 0xF)])
  writeUART(p[Int((v >> 24) & 0xF)])
  writeUART(p[Int((v >> 20) & 0xF)])
  writeUART(p[Int((v >> 16) & 0xF)])
  writeUART(p[Int((v >> 12) & 0xF)])
  writeUART(p[Int((v >>  8) & 0xF)])
  writeUART(p[Int((v >>  4) & 0xF)])
  writeUART(p[Int((v >>  0) & 0xF)])
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
func print(content: StaticString, to: OutputTarget = .UART) {
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
  let uartBase: UInt = 0x09000000 // FIXME: QEMU specific - use DTB instead
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

func printDec32(content value: UInt32, to: OutputTarget = .UART) {
  // special case 0
  if value == 0 {
    writeUART(48) // '0'
    return
  }
  
  // write numbers backwards into buffer (UInt32 max 10 counts)
  var buf: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0)
  var v   = value
  var len = 0
  
  while v > 0 {
    let digit = UInt8(v % 10) + 48  // 48 = ASCII '0'
    switch len {
    case 0: buf.0 = digit
    case 1: buf.1 = digit
    case 2: buf.2 = digit
    case 3: buf.3 = digit
    case 4: buf.4 = digit
    case 5: buf.5 = digit
    case 6: buf.6 = digit
    case 7: buf.7 = digit
    case 8: buf.8 = digit
    default: buf.9 = digit
    }
    len &+= 1
    v /= 10
  }
  // Rückwärts ausgeben (len-1 bis 0)
  var i = len - 1
  while i >= 0 {
    switch i {
    case 0: writeUART(buf.0)
    case 1: writeUART(buf.1)
    case 2: writeUART(buf.2)
    case 3: writeUART(buf.3)
    case 4: writeUART(buf.4)
    case 5: writeUART(buf.5)
    case 6: writeUART(buf.6)
    case 7: writeUART(buf.7)
    case 8: writeUART(buf.8)
    default: writeUART(buf.9)
    }
    i &-= 1
  }
}

func printCStr(_ p: UnsafeRawPointer) {
  var i = 0
  while true {
    let b = p.load(fromByteOffset: i, as: UInt8.self)
    if b == 0 { break }
    writeUART(b)
    i &+= 1
  }
}

