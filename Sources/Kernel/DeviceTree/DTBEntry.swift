// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

/// A entry in the Devicetree blob
struct DTBEntry {
  
  /// Typesafe type of Devicetree entry
  let type:       DTBEntryType
  
  // beginNode
  let nodeName:   UnsafeRawPointer?

  // property
  let propName:   UnsafeRawPointer?   // zeigt in den Strings-Block
  let propValue:  UnsafeRawPointer?   // zeigt in den Struct-Block
  let propLength: UInt32
  
  // depth after this entry
  let depth:      Int
}

