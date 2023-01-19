///Log等级，用于指定 BleManager 的 logLevel
class BleLogLevel {
  ///不输出log日志
  static const int none = 1 << 0;

  ///输出系统级的日志
  static const int system = 1 << 1;

  ///输出库的日志
  static const int lib = 1 << 2;
}
