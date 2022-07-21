import 'dart:typed_data';

class Constants {
  /// Used to advertise service
  static final Uint8List serviceManufacturerTag =
      Uint8List.fromList([0x11, 0x17, 0x51, 0x34]);

  /// Used to authenticate the central device
  static final Uint8List verifyTag =
      Uint8List.fromList([0x10, 0x16, 0x50, 0x33]);
}
