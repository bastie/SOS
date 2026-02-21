// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

/// count of null-terminate String
func cstrLen(_ p: UnsafeRawPointer) -> Int {
  var i = 0
  while p.load(fromByteOffset: i, as: UInt8.self) != 0 { i &+= 1 }
  return i
}

/// Compare tow null-terminate Strings (cStrings)
func cstrEqual(_ a: UnsafeRawPointer, _ b: UnsafeRawPointer) -> Bool {
  var i = 0
  while true {
    let ca = a.load(fromByteOffset: i, as: UInt8.self)
    let cb = b.load(fromByteOffset: i, as: UInt8.self)
    guard ca == cb else { return false }
    if ca == 0 { return true }
    i &+= 1
  }
}

/// Compare wirh StaticString-Literal (utf8Start without Closure!)
///
///   cstrEqual(namePtr, "memory")
func cstrEqual(_ a: UnsafeRawPointer, _ literal: StaticString) -> Bool {
  // StaticString.utf8Start: UnsafePointer<UInt8> – direkt verfügbar, kein Closure
  cstrEqual(a, UnsafeRawPointer(literal.utf8Start))
}


/// Prefix-Check without stdlib
func hasPrefix(_ str: UnsafeRawPointer, _ prefix: StaticString) -> Bool {
  let pfx = UnsafeRawPointer(prefix.utf8Start)
  var i = 0
  while true {
    let pb = pfx.load(fromByteOffset: i, as: UInt8.self)
    if pb == 0 { return true }  // ganzes Präfix gefunden
    let sb = str.load(fromByteOffset: i, as: UInt8.self)
    if pb != sb { return false }
    i &+= 1
  }
}
