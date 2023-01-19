import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/cases/base_case.dart';

class ScanCase extends CaseBase {
  static const String tag = "ScanCase";

  @override
  Future<void> start() async {
    bleex.listenScanAddDevice(deviceScanHandler);
    bleex.listenScanUpdateDevice(deviceScanHandler);
    bleex.scanDevices();
  }

  void deviceScanHandler(DiscoveredDevice device) {
    bleLog(tag, '$device');
  }
}
