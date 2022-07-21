import 'package:ble_ex/src/ble_log_level.dart';
import 'package:ble_ex/src/ble_manager.dart';

///内部日志输出
void bleLog(String tag, String msg) {
  if (BleManager.logLevel & BleLogLevel.none == 0 &&
      BleManager.logLevel & BleLogLevel.lib != 0) {
    print("[BleLog: $tag] $msg");
  }
}
