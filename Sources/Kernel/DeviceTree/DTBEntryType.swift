// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

/// The devicetree-specifcation lexical structure defines five tokens
/// - SeeAlso [Devicetree specification version 0.4, site 53](https://github.com/devicetree-org/devicetree-specification/releases/download/v0.4/devicetree-specification-v0.4.pdf)
enum DTBEntryType : UInt32 {
  
  /// mark the beginning of a node
  case beginNode = 0x0000_0001
  /// mark the end of a node
  case endNode = 0x0000_0002
  /// marks the beginng of a property
  case property = 0x0000_0003
  /// an no operation node should be ignored, because this is for writers to remove property without change the tree
  case nop = 0x0000_0004
  /// the end and last node of devicetree is reached
  case end = 0x0000_0009
  /// an helper value, to respect devicetree writer errors, take a coffee and run!
  case invalid = 0xFADE_C0DE
}
