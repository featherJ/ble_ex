import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/cases/base_case.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class ScanCase extends CaseBase {
  static const String tag = "ScanCase";

  @override
  Future<void> start() async {
    bleManager.listenScanAddDevice(deviceScanHandler);
    bleManager.listenScanUpdateDevice(deviceScanHandler);
    bleManager.scanDevices();
  }

  void deviceScanHandler(DiscoveredDevice device) {
    bleLog(tag, '$device');
  }
}
