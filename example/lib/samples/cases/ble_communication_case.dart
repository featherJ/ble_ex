import 'dart:typed_data';

import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/ble_uuids.dart';
import 'package:ble_ex_example/samples/cases/base_case.dart';
import 'package:ble_ex_example/samples/constants.dart';

class BleCommunicationCase extends CaseBase {
  static const String tag = "BleCommunicationCase";
  @override
  BlePeripheral createPeripheral(DiscoveredDevice device) {
    var peripheral = super.createPeripheral(device);
    peripheral.addNotifyListener(
        BleUUIDs.service1, BleUUIDs.indicateTest, indicateHandler);
    peripheral.addNotifyListener(
        BleUUIDs.service2, BleUUIDs.notifyTest, notifyHandler);
    return peripheral;
  }

  void indicateHandler(BlePeripheral target, Uuid s, Uuid c, Uint8List data) {
    bleLog(tag,
        "Received indicate: (length: ${data.length}) ${data.toList()} from service1");
  }

  void notifyHandler(BlePeripheral target, Uuid s, Uuid c, Uint8List data) {
    bleLog(tag,
        "Received notify: (length: ${data.length}) ${data.toList()} from service2");
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
    bleLog(tag, "Reading from peripheral");
    try {
      var data = await peripheral.read(BleUUIDs.service1, BleUUIDs.readTest);
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
      await peripheral.writeWithoutResponse(
          BleUUIDs.service1, BleUUIDs.writeTest, Uint8List.fromList(data));
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
      await peripheral.writeWithResponse(
          BleUUIDs.service1, BleUUIDs.writeTest, Uint8List.fromList(data));
      bleLog(tag,
          "Writing with response data: (length: ${data.length}) $data to peripheral");
    } catch (e) {
      bleLog(tag, "Write with response to peripheral error: ${e.toString()}");
    }
  }
}
