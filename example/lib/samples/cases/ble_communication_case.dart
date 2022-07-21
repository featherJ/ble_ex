import 'dart:typed_data';

import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/ble_uuids.dart';
import 'package:ble_ex_example/samples/cases/base_case.dart';
import 'package:ble_ex_example/samples/constants.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleCommunicationCase extends CaseBase {
  static const String tag = "BleCommunicationCase";

  @override
  BlePeripheralService createPeripheral(
      DiscoveredDevice device, Uuid serviceId) {
    var peripheral = super.createPeripheral(device, serviceId);
    peripheral.addNotifyListener(BleUUIDs.baseNotifyTest, nofityHandler);
    return peripheral;
  }

  void nofityHandler(dynamic target, Uint8List data) {
    bleLog(tag,
        "Received notify: (length: ${data.length}) ${data.toList()} from peripheral");
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

    bleLog(tag, "Reading from peripheral");
    try {
      var data = await peripheral.readCharacteristic(BleUUIDs.baseReadTest);
      bleLog(tag,
          "Readed data: (length: ${data.length}) ${data.toList()} from peripheral");
    } catch (e) {
      bleLog(tag, "Read from peripheral error: ${e.toString()}");
    }

    bleLog(tag, " ---------------------------------- ");

    bleLog(tag, "Writing without response to peripheral");
    try {
      List<int> data = [];
      for (var i = 0; i < 20; i++) {
        data.add(1);
      }
      await peripheral.writeCharacteristicWithoutResponse(
          BleUUIDs.baseWriteTest, Uint8List.fromList(data));
      bleLog(tag,
          "Writing without response data: (length: ${data.length}) $data to peripheral");
    } catch (e) {
      bleLog(
          tag, "Write without response to peripheral error: ${e.toString()}");
    }

    bleLog(tag, " ---------------------------------- ");

    bleLog(tag, "Writing with response to peripheral");
    try {
      List<int> data = [];
      for (var i = 0; i < 20; i++) {
        data.add(2);
      }
      await peripheral.writeCharacteristicWithResponse(
          BleUUIDs.baseWriteTest, Uint8List.fromList(data));
      bleLog(tag,
          "Writing with response data: (length: ${data.length}) $data to peripheral");
    } catch (e) {
      bleLog(tag, "Write with response to peripheral error: ${e.toString()}");
    }
  }
}
