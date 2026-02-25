// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

/// A stack-only (no heap) Devicetree blob parser.
struct DTBParser {
  private let structBase:  UnsafeRawPointer
  private let stringsBase: UnsafeRawPointer
  private let structEnd:   Int   // exclusive, Bytes
  private var cursor:      Int   // byte-offset in structBase
  private var _depth:      Int
  
  /// init the parser 
  init?(dtbBase: UnsafeRawPointer) {
    let hdr = DTBHeader.read(from: dtbBase)
    guard hdr.isValid else { return nil }
    
    structBase  = dtbBase.advanced(by: Int(hdr.offDtStruct))
    stringsBase = dtbBase.advanced(by: Int(hdr.offDtStrings))
    structEnd   = Int(hdr.sizeDtStruct)
    cursor      = 0
    _depth      = 0
  }
  
  var currentDepth: Int { _depth }
  var isDone: Bool      { cursor >= structEnd }
  
  /// Read all needed informations from DTB into struct on stack
  /// - Parameters
  ///   - dtbBase is the adress from Assembler - on AArch64 rx0 as first parameter in our kernal
  ///   - info the struct to store this informations
  /// - Note:  info is given over inout to be save on stack
  mutating func parseDTB(dtbBase: UnsafeRawPointer, into info : inout DTBInfo) {

    // ── Step 1: read DTB Header Reservation Map ────────────────
    // from header – before read Structure block
    let hdr = DTBHeader.read(from: dtbBase)
    var rsvp = dtbBase.advanced(by: Int(hdr.offMemRsvmap))
    
    while true {
      let addr = beLoad64(rsvp)
      let size = beLoad64(rsvp.advanced(by: 8))
      rsvp = rsvp.advanced(by: 16)
      
      if addr == 0 && size == 0 { break }  // Terminator
      
      // Bootload-Reserved: noMap, never ever touch!
      info.reservations.append(ReservedRegion(baseAdress: addr, size: size, noMap: false))
    }
    
    // ── Step 2: iterate over Structure Block iterieren ──────────
    var inMemory   = false
    var inChosen   = false
    var inRoot     = false
    
    var inReservedMem   = false
    var inReservedChild = false
    var currentNoMap    = false
    
    loop: while true {
      let entry = self.next()
      
      switch entry.type {
      case .nop:
        break
      case .end, .invalid:
        break loop
        
      case .beginNode:
#if DEBUG
        print(content: "NODE: [")
        if let n = entry.nodeName {
          printCStr(n)       
        }
        print(content: "]\n")
#endif
        guard let name = entry.nodeName else { continue }
        let d = entry.depth
#if DEBUG
        // ── DEBUG ──────────────────────
        print(content: "NODE d=")
        printHex32(content: UInt32(d))
        print(content: " [")
        printCStr(name)
        print(content: "]\n")
        // ── inMemory trace ─────────────
        if d == 2 {
          let isM = cstrEqual(name, "memory") || hasPrefix(name, "memory@")
          print(content: isM ? "  → inMemory=TRUE\n" : "  → inMemory=false\n")
          inMemory = isM
          inChosen = cstrEqual(name, "chosen")
        }
        // ───────────────────────────────
#endif
        if d == 1 {
          inRoot          = true
          inMemory        = false
          inChosen        = false
          inReservedMem   = false
          inReservedChild = false
        }
        else {
          if d == 2 {
            inMemory        = (cstrEqual(name, "memory") || hasPrefix(name, "memory@"))
            inChosen        = cstrEqual(name, "chosen")
            inReservedMem   = cstrEqual(name, "reserved-memory")
            inReservedChild = false
          }
          else {
            if d == 3 && inReservedMem {
              inReservedChild = true
              currentNoMap    = false
            }
          }
        }
        
      case .endNode:
        if entry.depth == 1 {
          inRoot = false
        }
        if entry.depth < 2  {
          inMemory      = false
          inChosen      = false
          inReservedMem = false
        }
        if entry.depth < 3  { inReservedChild = false }
        
      case .property:
        guard let pname = entry.propName,
              let pval  = entry.propValue else { continue }
        let plen = entry.propLength
#if DEBUG
        // ── DEBUG ──────────────────────
        print(content: "  PROP d=")
        printHex32(content: UInt32(entry.depth))
        print(content: " name=[")
        printCStr(pname)
        print(content: "]\n")
        // ───────────────────────────────
#endif
        
        // ── Root-Properties ────────────────────────────────────────
        if inRoot && entry.depth == 1 {
          if cstrEqual(pname, "#address-cells") && plen >= 4 {
            info._addressCells = beLoad32(pval)
          }
          else {
            if cstrEqual(pname, "#size-cells") && plen >= 4 {
              info._sizeCells = beLoad32(pval)
            }
          }
        }
        
        // ── Memory-Node ────────────────────────────────────────────
        if inMemory, cstrEqual(pname, "reg") {
          let cellBytes = Int(info._addressCells &* 4 + info._sizeCells &* 4)
          var off = 0
          while off + cellBytes <= Int(plen) {
            let base: UInt64
            let size: UInt64
            
            if info._addressCells == 2 {
              base = beLoad64(pval.advanced(by: off))
              off &+= 8
            }
            else {
              base = UInt64(beLoad32(pval.advanced(by: off)))
              off &+= 4
            }
            
            if info._sizeCells == 2 {
              size = beLoad64(pval.advanced(by: off))
              off &+= 8
            }
            else {
              size = UInt64(beLoad32(pval.advanced(by: off)))
              off &+= 4
            }
            
            if size > 0 {
              info.memory.append(MemoryRegion(base: base, size: size))
            }
          }
        }
        
        // ── Reserved-Memory Sub-Nodes ──────────────────────────────
        if inReservedChild && entry.depth == 3 {
          if cstrEqual(pname, "no-map") {
            currentNoMap = true
          }
          if cstrEqual(pname, "reg") && plen >= 16 {
            let base = beLoad64(pval)
            let size = beLoad64(pval.advanced(by: 8))
            if size > 0 {
              info.reservations.append(ReservedRegion(baseAdress: base, size: size, noMap: currentNoMap))
            }
          }
        }
        
        // ── Chosen-Node ────────────────────────────────────────────
        if inChosen {
          if cstrEqual(pname, "stdout-path") {
            info.chosen.stdoutPath = pval
          } else {
            if cstrEqual(pname, "linux,initrd-start") && plen >= 4 {
              info.chosen.initrdStart = plen == 8 ? beLoad64(pval) : UInt64(beLoad32(pval))
            }
            else {
              if cstrEqual(pname, "linux,initrd-end") && plen >= 4 {
                info.chosen.initrdEnd = plen == 8 ? beLoad64(pval) : UInt64(beLoad32(pval))
              }
              else {
                if cstrEqual(pname, "rng-seed") && plen > 0 {  // ← neu
                  info.chosen.rngSeed    = pval
                  info.chosen.rngSeedLen = Int(plen)
                }
              }
            }
          }
        }
      }
    }
  }
  /// Read the next entry
  /// - Returns DTBEntry next
  mutating func next() -> DTBEntry {
    
    while cursor + 4 <= structEnd {
      var token = DTBEntryType(rawValue: beLoad32(structBase.advanced(by: cursor)))
      if nil == token {
        token = .invalid
      }
      cursor &+= 4
      
      switch token {
        
        // ── BEGIN_NODE ──────────────────────────────────────────────
      case .beginNode:
        let namePtr = structBase.advanced(by: cursor)
        let nameLen = cstrLen(namePtr)
        cursor &+= alignUp4(nameLen + 1)   // for the Null-Byte add 1
        _depth &+= 1
        return DTBEntry(
          type: .beginNode, nodeName: namePtr,
          propName: nil, propValue: nil, propLength: 0,
          depth: _depth)
        
        // ── END_NODE ─────────────────────────────────────────────────
      case .endNode:
        _depth &-= 1
        return DTBEntry(
          type: .endNode, nodeName: nil,
          propName: nil, propValue: nil, propLength: 0,
          depth: _depth)
        
        // ── PROP ─────────────────────────────────────────────────────
      case .property:
        guard cursor + 8 <= structEnd else { break }
        let propLen = beLoad32(structBase.advanced(by: cursor))
        let nameOff = Int(beLoad32(structBase.advanced(by: cursor &+ 4)))
        cursor &+= 8
        
        let valuePtr = structBase.advanced(by: cursor)
        let namePtr  = stringsBase.advanced(by: nameOff)
        cursor &+= alignUp4(Int(propLen))
        
        return DTBEntry(
          type: .property, nodeName: nil,
          propName: namePtr, propValue: valuePtr, propLength: propLen,
          depth: _depth)
        
        // ── NOP ──────────────────────────────────────────────────────
      case .nop:
        continue
        
        // ── END ──────────────────────────────────────────────────────
      case .end:
        return DTBEntry(
          type: .end, nodeName: nil,
          propName: nil, propValue: nil, propLength: 0,
          depth: 0)
        
        // ── OTHER ────────────────────────────────────────────────────
      default:
        break
      }
    }
    
    return DTBEntry(
      type: .invalid, nodeName: nil,
      propName: nil, propValue: nil, propLength: 0,
      depth: 0)
  }
}


// MARK: Helper functions

/// Alignment to 4 bytes required by Devicetree blob parsing
@inline(__always)
func alignUp4(_ n: Int) -> Int {
  (n + 3) & ~3
}


// ARM DTB is Big-Endian, loads in result of some issues but perhaps later removeable

@inline(__always)
func beLoad32(_ p: UnsafeRawPointer) -> UInt32 {
  let b0 = UInt32(p.load(fromByteOffset: 0, as: UInt8.self))
  let b1 = UInt32(p.load(fromByteOffset: 1, as: UInt8.self))
  let b2 = UInt32(p.load(fromByteOffset: 2, as: UInt8.self))
  let b3 = UInt32(p.load(fromByteOffset: 3, as: UInt8.self))
  return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
}

@inline(__always)
func beLoad64(_ p: UnsafeRawPointer) -> UInt64 {
  let hi = UInt64(beLoad32(p))
  let lo = UInt64(beLoad32(p.advanced(by: 4)))
  return (hi << 32) | lo
}

