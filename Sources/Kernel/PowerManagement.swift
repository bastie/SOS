// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

/// type safe hardware controlling
enum PowerActionAArch64: UInt32 {
  /// shutdown our system
  case shutdown = 0x8400_0008
  /// reset our system
  case reset    = 0x8400_0009
}

extension PowerActionAArch64 {
  /// Type-save function to perform an `PowerAction`
  /// - Parameter action to perform
  static func perform(_ action: PowerActionAArch64) {
    // from Kernel we need to ask ARM exception level 2 (hypervisor) do power management functions
    armServiceOnExceptionLevel2 (action.rawValue)
  }
}

