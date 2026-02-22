// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

@_cdecl("putchar")
public func putchar(_ char: Int32) -> Int32 {
  guard char >= 0 && char <= UInt8.max else {
    // EOF = -1
    return -1
  }
  
  // write to UART
  return Int32(writeUART(UInt8(char)))
  //return fputc(char, stdout)
}

@_cdecl("memmove")
public func memmove(_ dest: UnsafeMutableRawPointer?,
                    _ src: UnsafeRawPointer?,
                    _ n: Int) -> UnsafeMutableRawPointer? {
  
  // 1. check nil and n=0 optimizing
  guard let dPtr = dest, let sPtr = src, n > 0 else { return dest }
  
  // 2. compare address as numbers
  let dAddr = UInt(bitPattern: dPtr)
  let sAddr = UInt(bitPattern: sPtr)
  
  // we want access over bytes
  let d = dPtr.assumingMemoryBound(to: UInt8.self)
  let s = sPtr.assumingMemoryBound(to: UInt8.self)
  
  if dAddr < sAddr {
    // target before source - secure forward copy
    for i in 0..<n {
      d[i] = s[i]
    }
  } else if dAddr > sAddr {
    // target after source - do not overlap and so backward copy
    for i in (0..<n).reversed() {
      d[i] = s[i]
    }
  }
  return dest
}
