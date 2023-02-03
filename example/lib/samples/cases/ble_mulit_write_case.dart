import 'dart:typed_data';

import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/ble_uuids.dart';
import 'package:ble_ex_example/samples/cases/base_case.dart';
import 'package:ble_ex_example/samples/constants.dart';

class BleMultiWriteCase extends CaseBase {
  static const String tag = "BleCommunicationCase";
  @override
  BlePeripheral createPeripheral(DiscoveredDevice device) {
    var peripheral = super.createPeripheral(device);
    return peripheral;
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

    bleLog(tag, " ---------------------------------- ");
    bleLog(tag, "Initialize the suggested mtu value");
    int suggestedMtu = await peripheral.requestSuggestedMtu();
    bleLog(tag, "Suggested mtu value is $suggestedMtu");

    bleLog(tag, " ---------------------------------- ");
    bleLog(tag, "request connection high performance");
    await peripheral
        .requestConnectionPriority(ConnectionPriority.highPerformance);

    bleLog(tag, " ---------------------------------- ");

    bleLog(tag, " ---------------------------------- ");
    bleLog(tag, "Writing with response to peripheral");

    for (var i = 0; i < 10; i++) {
      List<int> data = [];
      for (var j = 0; j < 20; j++) {
        data.add(i);
      }
      try {
        peripheral.writeWithResponse(
            BleUUIDs.service1, BleUUIDs.writeTest, Uint8List.fromList(data));
        bleLog(tag,
            "Writing with response data: (length: ${data.length}) $data to peripheral");
      } catch (e) {
        bleLog(tag, "Write with response to peripheral error: ${e.toString()}");
      }
    }
  }
}
