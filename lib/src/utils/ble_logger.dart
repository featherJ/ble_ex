import 'package:ble_ex/src/ble_ex.dart';
import 'package:ble_ex/src/utils/ble_log_level.dart';

///内部日志输出
void bleLog(String tag, String msg) {
  if (BleEx.logLevel & BleLogLevel.none == 0 &&
      BleEx.logLevel & BleLogLevel.lib != 0) {
    print("[BleLog: $tag] $msg");
  }
}
