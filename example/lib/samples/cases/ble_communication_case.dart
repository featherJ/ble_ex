import 'dart:typed_data';

import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/ble_uuids.dart';
import 'package:ble_ex_example/samples/cases/base_case.dart';
import 'package:ble_ex_example/samples/constants.dart';

class BleCommunicationCase extends CaseBase {
  static const String tag = "BleCommunicationCase";

  final int logId;
  BleCommunicationCase({required this.logId});

  @override
  BlePeripheralService createPeripheral(
      DiscoveredDevice device, Uuid serviceId) {
    var peripheral = super.createPeripheral(device, serviceId);
    peripheral.addNotifyListener(BleUUIDs.baseNotifyTest, nofityHandler);
    return peripheral;
  }

  var previousValue = -1;
  var previousTime = -1;
  var sumTime = 0;
  var numNotify = 0;
  void nofityHandler(dynamic target, Uint8List data) async {
    var list = data.toList();
    var firstValue = list[0];
    if (previousValue == -1) {
      previousValue = firstValue;
    } else {
      if (firstValue - previousValue != 1) {
        bleLog("{$tag}{$logId}",
            "---------------- fuck!!!!!!!!! $firstValue to $previousValue");
        // try {
        //   List<int> result = [];
        //   result.add(firstValue);
        //   result.add(previousValue);
        //   peripheral
        //       .writeCharacteristicWithResponse(
        //           BleUUIDs.baseNotifyResultTest, Uint8List.fromList(result))
        //       .then((value) {
        //     bleLog("{$tag}{$logId}", "sendresult success");
        //   }, onError: (e) {
        //     bleLog("{$tag}{$logId}", "sendresult error");
        //   });
        // } catch (e) {
        //   bleLog("{$tag}{$logId}", e.toString());
        // }
      }
      // else {
      //   List<int> result = [];
      //   result.add(0);
      //   result.add(0);
      //   peripheral
      //       .writeCharacteristicWithResponse(
      //           BleUUIDs.baseNotifyResultTest, Uint8List.fromList(result))
      //       .then((value) {
      //     bleLog("{$tag}{$logId}", "sendresult success");
      //   }, onError: (e) {
      //     bleLog("{$tag}{$logId}", "sendresult error");
      //   });
      // }
      previousValue = firstValue;
    }
    var timeStep = 0;
    if (previousTime == -1) {
      previousTime = DateTime.now().millisecondsSinceEpoch;
    } else {
      var time = DateTime.now().millisecondsSinceEpoch;
      timeStep = time - previousTime;
      previousTime = time;
    }
    sumTime += timeStep;
    numNotify++;
    var avgTime = sumTime / numNotify;
    var avgTime2 = avgTime.floor();
    bleLog("{$tag}{$logId}",
        "Received notify: (length: ${data.length}) firist:${list[0]} from peripheral cast:{$timeStep}ms avg:{$avgTime2}ms");
  }

  @override
  Future<void> connectedHandler(dynamic target) async {
    super.connectedHandler(target);
    bleLog("{$tag}{$logId}", " ---------------------------------- ");
    bleLog("{$tag}{$logId}", "Verify current device");
    try {
      Uint8List verifyResult =
          await peripheral.request(BleUUIDs.verifyCentral, Constants.verifyTag);
      if (verifyResult.isNotEmpty && verifyResult[0] == 1) {
        bleLog("{$tag}{$logId}", "verification succeeded");
      } else {
        bleLog("{$tag}{$logId}", "verification failed");
      }
    } catch (e) {
      bleLog(
          "{$tag}{$logId}", "Verifying current device error ${e.toString()}");
    }

    bleLog("{$tag}{$logId}", " ---------------------------------- ");

    bleLog("{$tag}{$logId}", "Initialize the suggested mtu value");
    int suggestedMtu = await peripheral.requestSuggestedMtu();
    bleLog("{$tag}{$logId}", "Suggested mtu value is $suggestedMtu");
    await peripheral
        .requestConnectionPriority(ConnectionPriority.highPerformance);

    bleLog("{$tag}{$logId}", " ---------------------------------- ");

    // bleLog("{$tag}{$logId}", "Reading from peripheral");
    // try {
    //   var data = await peripheral.readCharacteristic(BleUUIDs.baseReadTest);
    //   bleLog("{$tag}{$logId}",
    //       "Readed data: (length: ${data.length}) ${data.toList()} from peripheral");
    // } catch (e) {
    //   bleLog("{$tag}{$logId}", "Read from peripheral error: ${e.toString()}");
    // }

    // bleLog("{$tag}{$logId}", " ---------------------------------- ");

    bleLog("{$tag}{$logId}", "Writing without response to peripheral");
    try {
      List<int> data = [];
      for (var i = 0; i < 20; i++) {
        data.add(1);
      }
      await peripheral.writeCharacteristicWithoutResponse(
          BleUUIDs.baseWriteTest, Uint8List.fromList(data));
      // await peripheral.writeCharacteristicWithoutResponse(
      // BleUUIDs.baseNotifyResultTest, Uint8List.fromList(data));

      bleLog("{$tag}{$logId}",
          "Writing without response data: (length: ${data.length}) $data to peripheral");
    } catch (e) {
      bleLog("{$tag}{$logId}",
          "Write without response to peripheral error: ${e.toString()}");
    }

    // bleLog("{$tag}{$logId}", " ---------------------------------- ");
    // bleLog("{$tag}{$logId}", "Writing with response to peripheral");
    // try {
    //   List<int> data = [];
    //   for (var i = 0; i < 20; i++) {
    //     data.add(2);
    //   }
    //   await peripheral.writeCharacteristicWithResponse(
    //       BleUUIDs.baseWriteTest, Uint8List.fromList(data));
    //   bleLog("{$tag}{$logId}",
    //       "Writing with response data: (length: ${data.length}) $data to peripheral");
    // } catch (e) {
    //   bleLog("{$tag}{$logId}", "Write with response to peripheral error: ${e.toString()}");
    // }
  }
}
