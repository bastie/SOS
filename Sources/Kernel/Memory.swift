// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

/// Memory Region  (needed for RAM-Init)
struct MemoryRegion {
  let base: UInt64
  let size: UInt64
}

// TODO: switch to InlineArray after next commit
struct MemoryMap {
  /// Regions as tupel to create a fixed size collection on Stack, because Arrays works over Heap
  /// up to 8 RAM-regions – think enough for not a single system image kernel (SSI)
  var regions: (MemoryRegion, MemoryRegion, MemoryRegion, MemoryRegion,
                MemoryRegion, MemoryRegion, MemoryRegion, MemoryRegion)
  var offset: Int
  
  init() {
    let empty = MemoryRegion(base: 0, size: 0)
    regions = (empty,empty,empty,empty,empty,empty,empty,empty)
    offset   = 0
  }
  
  /// append an region
  mutating func append(_ r: MemoryRegion) {
    guard offset < 8 else { return }
    switch offset {
    case 0: regions.0 = r
    case 1: regions.1 = r
    case 2: regions.2 = r
    case 3: regions.3 = r
    case 4: regions.4 = r
    case 5: regions.5 = r
    case 6: regions.6 = r
    default: regions.7 = r
    }
    offset &+= 1
  }
  
  /// get region without normal Array (no Heap)
  func region(at i: Int) -> MemoryRegion {
    guard (i >= 0 && i <= 7) else {
      return MemoryRegion(base: 0, size: 0)
    }
    switch i {
    case 0: return regions.0
    case 1: return regions.1
    case 2: return regions.2
    case 3: return regions.3
    case 4: return regions.4
    case 5: return regions.5
    case 6: return regions.6
    default: return regions.7
    }
  }
}

struct ReservedRegion {
  
  /// Initialize the reserved region
  init(baseAdress: UInt64, size: UInt64, noMap: Bool) {
    self.baseAdress = baseAdress
    self.size = size
    self.noMap = noMap
  }
  
  let baseAdress: UInt64
  let size: UInt64
  // important to use not Bool, with UInt64 instead of Bool alignment is correct
  private var _noMap: UInt64 = 0
  // with computed property noMap we realize the correct align over the stored variable with UInt64 and the Bool-type-safety on using
  var noMap: Bool {
    get { _noMap != 0 }
    set { _noMap = newValue ? 1 : 0 }
  }
}

// TODO: switch to InlineArray after next commit

struct ReservationMap {
  var regions: (ReservedRegion, ReservedRegion, ReservedRegion, ReservedRegion,
                ReservedRegion, ReservedRegion, ReservedRegion, ReservedRegion)
  var count: Int
  
  init() {
    let empty = ReservedRegion(baseAdress: 0, size: 0, noMap: false)
    regions = (empty,empty,empty,empty,empty,empty,empty,empty)
    count   = 0
  }
  
  /// append an region
  mutating func append(_ r: ReservedRegion) {
    guard count < 8 else { return }
    switch count {
    case 0: regions.0 = r
    case 1: regions.1 = r
    case 2: regions.2 = r
    case 3: regions.3 = r
    case 4: regions.4 = r
    case 5: regions.5 = r
    case 6: regions.6 = r
    default: regions.7 = r
    }
    count &+= 1
  }
  
  /// get region without normal Array (no Heap)
  func region(at i: Int) -> ReservedRegion {
    guard (i >= 0 && i <= 7) else {
      return ReservedRegion(baseAdress: 0, size: 0, noMap: true)
    }
    switch i {
    case 0: return regions.0
    case 1: return regions.1
    case 2: return regions.2
    case 3: return regions.3
    case 4: return regions.4
    case 5: return regions.5
    case 6: return regions.6
    default: return regions.7
    }
  }
}
