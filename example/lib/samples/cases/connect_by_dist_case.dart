import 'dart:typed_data';

import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/ble_uuids.dart';
import 'package:ble_ex_example/samples/cases/base_case.dart';
import 'package:ble_ex_example/samples/constants.dart';
import 'package:ble_ex_example/samples/util.dart';

class ConnectByDistCase extends CaseBase {
  static const String tag = "ConnectByDistCase";

  late BleScanningTask scanningTask;
  @override
  Future<void> start() async {
    scanningTask = bleex.createScanningTask();
    scanningTask.addDeviceUpdateListener(deviceScanHandler);
    scanningTask.scanDevices(filters: [
      ManufacturerSampleFilter(Constants.serviceManufacturerTag).filter
    ]);
  }

  void deviceScanHandler(DiscoveredDevice device) {
    var hasTargetService = false;
    for (int i = 0; i < device.serviceUuids.length; i++) {
      if (device.serviceUuids[i].toString() == BleUUIDs.service1.toString()) {
        hasTargetService = true;
        break;
      }
    }
    if (hasTargetService) {
      var dist = calcDistByRSSI(device.id, device.rssi);
      if (dist > 0) {
        bleLog(tag,
            "Found device ${device.id} rssi:${device.rssi.toString()} dist:${dist.toString()}");
        if (dist <= 0.1) {
          scanningTask.stopScan();
          peripheral = createPeripheral(device);
          peripheral.connect();
        }
      }
    }
  }

  @override
  Future<void> connectedHandler(BlePeripheral target) async {
    super.connectedHandler(target);
    bleLog(tag, " ---------------------------------- ");
    bleLog(tag, "Verify current device");
    try {
      Uint8List verifyResult = await peripheral.request(
          BleUUIDs.service1, BleUUIDs.verifyCentral, Constants.verifyTag);
      if (verifyResult.isNotEmpty && verifyResult[0] == 1) {
        bleLog(tag, "verification succeeded");
      } else {
        bleLog(tag, "verification failed");
      }
    } catch (e) {
      bleLog(tag, "Verifying current device error ${e.toString()}");
    }
  }
}
