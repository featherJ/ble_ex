import 'dart:typed_data';

import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/ble_uuids.dart';
import 'package:ble_ex_example/samples/cases/base_case.dart';
import 'package:ble_ex_example/samples/constants.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleexCommunicationCase extends CaseBase {
  static const String tag = "BleexCommunicationCase";

  @override
  BlePeripheralService createPeripheral(
      DiscoveredDevice device, Uuid serviceId) {
    var peripheral = super.createPeripheral(device, serviceId);
    peripheral.addBytesListener(
        BleUUIDs.writeLargeDataToCentralTest, bytesHandler);
    return peripheral;
  }

  void bytesHandler(dynamic target, Uint8List data) {
    bleLog(tag,
        "Received bytes: (length: ${data.length}) ${data.toList()} from peripheral");
  }

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

    bleLog(tag, "Initialize the suggested mtu value");
    int suggestedMtu = await peripheral.requestSuggestedMtu();
    bleLog(tag, "Suggested mtu value is $suggestedMtu");

    bleLog(tag, " ---------------------------------- ");
    List<int> data = [];
    for (var i = 0; i < 5000; i++) {
      data.add(1);
    }
    bleLog(tag, "Writing large bytes(length: ${data.length}) to peripheral");
    try {
      await peripheral.writeBytes(
          BleUUIDs.writeLargeDataToPeripheralTest, Uint8List.fromList(data));
      bleLog(tag, "Write large bytes to peripheral succeeded");
    } catch (e) {
      bleLog(tag, "Write large bytes to peripheral error: ${e.toString()}");
    }

    bleLog(tag, " ---------------------------------- ");
    data = [];
    for (var i = 0; i < 5000; i++) {
      data.add(2);
    }
    bleLog(
        tag, "Requesting large bytes(length: ${data.length}) from peripheral");
    try {
      var reaultData = await peripheral.requestBytes(
          BleUUIDs.requestLargeDataTest, Uint8List.fromList(data));
      bleLog(tag,
          "Request large bytes(length: ${reaultData.length}) from peripheral succeeded: ${reaultData.toList()}");
    } catch (e) {
      bleLog(tag, "Request large bytes from peripheral error: ${e.toString()}");
    }
  }
}
