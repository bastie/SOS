// SPDX-License-Identifier: 0BSD
// SPDX-FileCopyrightText: © 2026 Sebastian Ritter

/// Chosen Node (Bootargs / initrd)
struct DTBChosenInfo {
  /// stdout path can contain our UART or our framebuffer
  var stdoutPath: UnsafeRawPointer?  // adress of DTB-Strings
  
  /// RAM disc start
  var initrdStart: UInt64
  /// RAM disc end
  var initrdEnd:   UInt64
}

