// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

/// The head of Devicetree blob
/// - SeeAlso [Specification](https://www.devicetree.org/specifications/)
public struct DTBHeader {
  /// the magic value of correct Devicetree blob
  public let DTB_MAGIC: UInt32 = 0xD00DFEED
  /// Is a valid head of Devicetree, if the magic value is same as in the data structure
  public var isValid: Bool { magic == DTB_MAGIC }

  // MARK: data structure
  let magic:            UInt32   // +0
  let totalSize:        UInt32   // +4
  let offDtStruct:      UInt32   // +8
  let offDtStrings:     UInt32   // +12
  let offMemRsvmap:     UInt32   // +16
  let version:          UInt32   // +20
  let lastCompVersion:  UInt32   // +24
  let bootCpuidPhys:    UInt32   // +28
  let sizeDtStrings:    UInt32   // +32
  let sizeDtStruct:     UInt32   // +36
  
  /// Read the Devicetree header directly at he adress without heap
  /// - Parameter base adress of Devicetree blob
  /// - Returns DTBHeader
  static func read(from base: UnsafeRawPointer) -> DTBHeader {
    DTBHeader(
      magic:           beLoad32(base.advanced(by:  0)),
      totalSize:       beLoad32(base.advanced(by:  4)),
      offDtStruct:     beLoad32(base.advanced(by:  8)),
      offDtStrings:    beLoad32(base.advanced(by: 12)),
      offMemRsvmap:    beLoad32(base.advanced(by: 16)),
      version:         beLoad32(base.advanced(by: 20)),
      lastCompVersion: beLoad32(base.advanced(by: 24)),
      bootCpuidPhys:   beLoad32(base.advanced(by: 28)),
      sizeDtStrings:   beLoad32(base.advanced(by: 32)),
      sizeDtStruct:    beLoad32(base.advanced(by: 36))
    )
  }
  
}
