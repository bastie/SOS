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
