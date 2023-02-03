import 'dart:typed_data';

import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/ble_uuids.dart';
import 'package:ble_ex_example/samples/cases/base_case.dart';
import 'package:ble_ex_example/samples/constants.dart';

class ReconnectCase extends CaseBase {
  static const String tag = "ReconnectCase";

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

    await Future.delayed(const Duration(milliseconds: 2000));
    bleLog(tag, "------- Disconnect manually -------");
    await peripheral.disconnect();
  }

  @override
  void disconnectedHandler(BlePeripheral target) {
    super.disconnectedHandler(target);
    bleLog(tag, "------- Reconnect manually -------");
    peripheral.connect();
  }
}
