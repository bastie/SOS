// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

// --- Minimal Runtime Support ---
// To link we need all these functions because Swift, yes also Embedded Swift, is not clearly freestanding

@_cdecl("memset")
public func memset(_ s: UnsafeMutableRawPointer, _ c: Int32, _ n: Int) -> UnsafeMutableRawPointer {
  let p = s.assumingMemoryBound(to: UInt8.self)
  for i in 0..<n { p[i] = UInt8(c) }
  return s
}

@_cdecl("posix_memalign")
public func posix_memalign(_ memptr: UnsafeMutablePointer<UnsafeMutableRawPointer?>, _ alignment: Int, _ size: Int) -> Int32 {
  // at this moment we don't have a heap and so we returns "Out of Memory" (ENOMEM = 12) zurück
  return 12
}

// Bad future bug is "Symbol name 'free' is reserved for the Swift runtime and cannot be directly referenced without causing unpredictable behavior; this will become an error"
@_cdecl("free")
public func free(_ ptr: UnsafeMutableRawPointer?) {
  // at this moment wie dont have something todo
}

@_cdecl("arc4random_buf")
public func arc4random_buf(_ buf: UnsafeMutableRawPointer, _ nbytes: Int) {
  let p = buf.assumingMemoryBound(to: UInt8.self)
  // 42 is the answer
  for i in 0..<nbytes { p[i] = 0x42 }
}
