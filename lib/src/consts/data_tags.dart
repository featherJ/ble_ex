part of ble_ex;

class _DataTags {
  /// M->S的长数据写的标签
  static final Uint8List msWriteLarge = Uint8List.fromList([120, 110]);

  /// S->M的长数据写的标签
  static final Uint8List smIndicateLarge = Uint8List.fromList([110, 100]);

  /// M->S的长数据请求的标签
  static final Uint8List msRequestLarge = Uint8List.fromList([88, 99]);

  /// S->M的长数据请求应答的标签
  static final Uint8List smResponseLarge = Uint8List.fromList([99, 88]);
}
