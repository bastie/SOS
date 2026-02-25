// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

/// Informations from Devicetree
struct DTBInfo {
  /// memory
  var memory:  MemoryMap   = MemoryMap()
  /// do not touch this memory or if you do it run fast!
  var reservations: ReservationMap = ReservationMap()
  // the chosen Devicetree informations
  var chosen:  DTBChosenInfo  = DTBChosenInfo(stdoutPath: nil, initrdStart: 0, initrdEnd: 0, rngSeed: nil, rngSeedLen: 0)
  // parsing information
  var _addressCells: UInt32 = 2   
  // parsing information
  var _sizeCells:    UInt32 = 2
}
