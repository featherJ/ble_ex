import 'dart:typed_data';

import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/ble_uuids.dart';
import 'package:ble_ex_example/samples/cases/base_case.dart';
import 'package:ble_ex_example/samples/constants.dart';

class BleexRequestCase extends CaseBase {
  static const String tag = "BleexRequestCase";

  @override
  Future<void> connectedHandler(dynamic target) async {
    super.connectedHandler(target);
    bleLog(tag, " ---------------------------------- ");
    bleLog(tag, "Verify current device");
    try {
      Uint8List verifyResult =
          await peripheral.request(BleUUIDs.verifyCentral, Constants.verifyTag);
      if (verifyResult.isNotEmpty && verifyResult[0] == 1) {
        bleLog(tag, "verification succeeded");
      } else {
        bleLog(tag, "verification failed");
      }
    } catch (e) {
      bleLog(tag, "Verifying current device error ${e.toString()}");
    }

    bleLog(tag, " ---------------------------------- ");
    List<int> data = [];
    for (var i = 0; i < 10; i++) {
      data.add(3);
    }
    bleLog(tag, "Requesting bytes(length: ${data.length}) from peripheral");
    try {
      var reaultData = await peripheral.request(
          BleUUIDs.requestDataTest, Uint8List.fromList(data));
      bleLog(tag,
          "Request bytes(length: ${reaultData.length}) from peripheral succeeded: ${reaultData.toList()}");
    } catch (e) {
      bleLog(tag, "Request bytes from peripheral error: ${e.toString()}");
    }
  }
}
