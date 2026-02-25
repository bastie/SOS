// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

// TODO: collect all assembler calls and platform specifcs in seperate source
@_silgen_name("_readMPIDR")
func _coreID() -> UInt64

///
/// - SeeAlso ADR 0003
struct AsconRNG {
  
  // ─── Typen ────────────────────────────────────
  
  private enum Phase {
    case uninitialized
    case singleCore
    case multiCore
  }
  
  private struct CoreRNG {
    var state:     InlineArray<5, UInt64> = .init(repeating: 0)
    var buffer:    InlineArray<3, UInt64> = .init(repeating: 0)
    var bufferPos: Int  = 24
    var initialized: Bool = false
  }
  
  // ─── State ────────────────────────────────────
  
  private var phase:          Phase = .uninitialized
  private var singleCore:     CoreRNG = CoreRNG()
  private var coreBase:       UnsafeMutablePointer<CoreRNG>? = nil
  private var coreCount:      Int = 0
  private var savedSeed:      InlineArray<6, UInt64> = .init(repeating: 0)
  private var savedSeedLen:   Int = 0
  
  // ─── round-constants ─────────────────────────
  // No Array, no InlineArray — constants
  @inline(__always)
  private func roundConstant(_ i: Int) -> UInt64 {
    switch i {
    case  0: return 0xf0
    case  1: return 0xe1
    case  2: return 0xd2
    case  3: return 0xc3
    case  4: return 0xb4
    case  5: return 0xa5
    case  6: return 0x96
    case  7: return 0x87
    case  8: return 0x78
    case  9: return 0x69
    case 10: return 0x5a
    default: return 0x4b
    }
  }
  
  private func permute12(_ s: inout InlineArray<5, UInt64>) {
    asconRound(&s, roundConstant(0))
    asconRound(&s, roundConstant(1))
    asconRound(&s, roundConstant(2))
    asconRound(&s, roundConstant(3))
    asconRound(&s, roundConstant(4))
    asconRound(&s, roundConstant(5))
    asconRound(&s, roundConstant(6))
    asconRound(&s, roundConstant(7))
    asconRound(&s, roundConstant(8))
    asconRound(&s, roundConstant(9))
    asconRound(&s, roundConstant(10))
    asconRound(&s, roundConstant(11))
  }
  
  // ─── Ascon Permutation ────────────────────────
  
  @inline(__always)
  private func ror64(_ x: UInt64, _ n: Int) -> UInt64 {
    (x &>> n) | (x &<< (64 - n))
  }
  
  @inline(__always)
  private func asconRound(_ s: inout InlineArray<5, UInt64>, _ c: UInt64) {
    s[2] ^= c
    
    s[0] ^= s[4]; s[4] ^= s[3]; s[2] ^= s[1]
    let t0 = ~s[0] & s[1]; let t1 = ~s[1] & s[2]
    let t2 = ~s[2] & s[3]; let t3 = ~s[3] & s[4]
    let t4 = ~s[4] & s[0]
    s[0] ^= t1; s[1] ^= t2; s[2] ^= t3; s[3] ^= t4; s[4] ^= t0
    s[1] ^= s[0]; s[0] ^= s[4]; s[3] ^= s[2]; s[2] = ~s[2]
    
    s[0] ^= ror64(s[0], 19) ^ ror64(s[0], 28)
    s[1] ^= ror64(s[1], 61) ^ ror64(s[1], 39)
    s[2] ^= ror64(s[2],  1) ^ ror64(s[2],  6)
    s[3] ^= ror64(s[3], 10) ^ ror64(s[3], 17)
    s[4] ^= ror64(s[4],  7) ^ ror64(s[4], 41)
  }
  
  @inline(__always)
  private func extractByte(
    from array: inout InlineArray<6, UInt64>,
    at byteIndex: Int
  ) -> UInt8 {
    UInt8((array[byteIndex / 8] &>> ((byteIndex % 8) * 8)) & 0xFF)
  }
  
  // ─── CoreRNG operations ──────────────────────
  
  private func initCore(
    _ core: inout CoreRNG,
    seed: inout InlineArray<6, UInt64>,
    seedLen: Int,
    coreID: UInt32
  ) {
    for wordIdx in 0..<5 {
      var word: UInt64 = 0
      for byteIdx in 0..<8 {
        let srcIdx = wordIdx * 8 + byteIdx
        let byte: UInt64 = srcIdx < seedLen
        ? UInt64(extractByte(from: &seed, at: srcIdx))
        : 0
        word |= byte &<< (byteIdx * 8)
      }
      core.state[wordIdx] = word
    }
    core.state[4] ^= UInt64(coreID)
    permute12(&core.state)
    core.bufferPos   = 24
    core.initialized = true
  }
  
  private func refill(_ core: inout CoreRNG) {
    permute12(&core.state)
    core.buffer[0] = core.state[0]
    core.buffer[1] = core.state[1]
    core.buffer[2] = core.state[2]
    core.bufferPos = 0
  }
  
  private func fill(_ core: inout CoreRNG, _ buf: UnsafeMutableRawPointer, _ nbytes: Int) {
    var remaining = nbytes
    var outOffset = 0
    while remaining > 0 {
      if core.bufferPos >= 24 { refill(&core) }
      let available = 24 - core.bufferPos
      let toCopy    = remaining < available ? remaining : available
      for i in 0..<toCopy {
        let pos     = core.bufferPos + i
        let byte    = UInt8((core.buffer[pos / 8] &>> ((pos % 8) * 8)) & 0xFF)
        buf.storeBytes(of: byte, toByteOffset: outOffset + i, as: UInt8.self)
      }
      core.bufferPos += toCopy
      outOffset      += toCopy
      remaining      -= toCopy
    }
  }
  
  // ─── Seed store ─────────────────────────────
  
  private mutating func saveSeed(seed: UnsafeRawPointer, seedLen: Int) {
    let toCopy = seedLen < 48 ? seedLen : 48
    for byteIdx in 0..<toCopy {
      let bitShift = (byteIdx % 8) * 8
      let byte     = UInt64(seed.load(fromByteOffset: byteIdx, as: UInt8.self))
      savedSeed[byteIdx / 8] = (savedSeed[byteIdx / 8] & ~(0xFF &<< bitShift))
      | (byte &<< bitShift)
    }
    savedSeedLen = toCopy
  }
  
  // ─── public API ──────────────────────────
  
  /// Phase 1: asap
  mutating func initSingleCore(seed: UnsafeRawPointer, seedLen: Int) {
    saveSeed(seed: seed, seedLen: seedLen)
    initCore(&singleCore, seed: &savedSeed, seedLen: savedSeedLen, coreID: 0)
    phase = .singleCore
  }
  
  /// Phase 2: if heap and multi core
  mutating func initMultiCore(
    count: Int,
    allocate: (Int) -> UnsafeMutableRawPointer
  ) {
    let newBase = allocate(count * MemoryLayout<CoreRNG>.stride)
      .assumingMemoryBound(to: CoreRNG.self)
    
    newBase[0] = singleCore
    for i in 1..<count {
      initCore(&newBase[i], seed: &savedSeed, seedLen: savedSeedLen, coreID: UInt32(i))
    }
    
    coreBase  = newBase
    coreCount = count
    phase     = .multiCore
  }
  
  /// call only from ``arc4random_buf(_:_:)``
  mutating func fill(_ buf: UnsafeMutableRawPointer, _ nbytes: Int) {
    switch phase {
    case .singleCore:
      fill(&singleCore, buf, nbytes)
    case .multiCore:
      let id  = Int(_coreID() & 0xFF)
      let rng = coreBase!.advanced(by: id < coreCount ? id : 0)
      fill(&rng.pointee, buf, nbytes)
    case .uninitialized:
      for i in 0..<nbytes {
        buf.storeBytes(of: UInt8(0), toByteOffset: i, as: UInt8.self)
      }
    }
  }
}
