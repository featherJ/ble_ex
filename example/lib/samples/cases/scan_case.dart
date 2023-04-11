import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/cases/base_case.dart';

class ScanCase extends CaseBase {
  static const String tag = "ScanCase";

  @override
  Future<void> start() async {
    var task1 = bleex.createScanningTask();
    var task2 = bleex.createScanningTask();

    task1.addDeviceUpdateListener(deviceUpdateHandler1);
    task2.addDeviceUpdateListener(deviceUpdateHandler2);

    bleLog(tag, 'Task1 starting');
    task1.scanDevices();

    Future.delayed(const Duration(milliseconds: 2000)).then((value) {
      bleLog(tag, 'Task2 starting');
      task2.scanDevices();
    });

    Future.delayed(const Duration(milliseconds: 6000)).then((value) {
      bleLog(tag, 'Task1 stopped');
      task1.stopScan();
    });

    Future.delayed(const Duration(milliseconds: 10000)).then((value) {
      bleLog(tag, 'Task2 stopped');
      task2.stopScan();
    });
  }

  void deviceUpdateHandler1(DiscoveredDevice device) {
    bleLog(tag, 'Device update on task1');
  }

  void deviceUpdateHandler2(DiscoveredDevice device) {
    bleLog(tag, 'Device update on task2');
  }
}
