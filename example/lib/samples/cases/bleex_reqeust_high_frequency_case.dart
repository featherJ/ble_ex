import 'dart:typed_data';

import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/ble_uuids.dart';
import 'package:ble_ex_example/samples/cases/base_case.dart';
import 'package:ble_ex_example/samples/constants.dart';

class BleexRequestHighFrequencyCase extends CaseBase {
  static const String tag = "BleexRequestHighFrequencyCase";

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
    request(1);
    request(2);
    request(3);
    request(4);
    request(5);
    request(6);
    request(7);
    request(8);
    request(9);
    request(10);
    request(11);
    request(12);
    request(13);
    request(14);
    request(15);
    request(16);
    request(17);
    request(18);
    request(19);
    request(20);
  }

  request(int index) async {
    List<int> data = [];
    for (var i = 0; i < 500; i++) {
      data.add(index);
    }
    bleLog(
        tag, "Requesting bytes(length: ${data.length}) from peripheral $index");
    try {
      var reaultData = await peripheral.requestLarge(BleUUIDs.service1,
          BleUUIDs.requestLargeTest, Uint8List.fromList(data));
      bleLog(tag,
          "Request bytes(length: ${reaultData.length}) from peripheral $index succeeded: ${reaultData.toList()}");
    } catch (e) {
      bleLog(
          tag, "Request bytes from peripheral $index error: ${e.toString()}");
    }
  }
}
