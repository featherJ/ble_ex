import 'dart:async';

import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/ble_uuids.dart';
import 'package:ble_ex_example/samples/cases/base_case.dart';
import 'package:ble_ex_example/samples/cases/ble_communication_case.dart';
import 'package:ble_ex_example/samples/cases/bleex_communication_case.dart';
import 'package:ble_ex_example/samples/cases/bleex_reqeust_case.dart';
import 'package:ble_ex_example/samples/cases/bleex_reqeust_high_frequency_case.dart';
import 'package:ble_ex_example/samples/cases/reconnect_case.dart';
import 'package:ble_ex_example/samples/cases/verify_central_case.dart';
import 'package:flutter/material.dart';

const String tag = "Main";
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // final flutterReactiveBle = FlutterReactiveBle();
  // StreamSubscription<DiscoveredDevice>? scanning;
  // scanning = flutterReactiveBle
  //     .scanForDevices(withServices: [BleUUIDs.service]).listen((device) {
  //   scanning!.cancel();
  //   print("Find device $device");
  //   flutterReactiveBle.connectToDevice(id: device.id).listen(
  //       (connectionState) async {
  //     print("connected state changed $connectionState");
  //     if (connectionState.connectionState == DeviceConnectionState.connected) {
  //       await flutterReactiveBle.requestMtu(deviceId: device.id, mtu: 512);
  //       start(flutterReactiveBle, device, BleUUIDs.service, 1);
  //       // start(flutterReactiveBle, device, BleUUIDs.service2, 2);
  //     }
  //   }, onError: (Object error) {
  //     print("connected error $error");
  //   });
  // }, onError: (e) {
  //   print("Scan error with $e");
  // });

  BleManager.logLevel = BleLogLevel.lib;
  bleLog(tag, "Running");
  var bleManager = BleManager();
  runSampleCase(bleManager);
}

// void start(FlutterReactiveBle flutterReactiveBle, DiscoveredDevice device,
//     Uuid service, int logId) async {
//   var previousTime = -1;
//   var sumTime = 0;
//   var numNotify = 0;

//   print("Add subscribeToCharacteristic");
//   var characteristic = QualifiedCharacteristic(
//       serviceId: service,
//       characteristicId: BleUUIDs.baseNotifyTest,
//       deviceId: device.id);
//   flutterReactiveBle.subscribeToCharacteristic(characteristic).listen((data) {
//     // print("receive data $data");
//     var timeStep = 0;
//     if (previousTime == -1) {
//       previousTime = DateTime.now().millisecondsSinceEpoch;
//     } else {
//       var time = DateTime.now().millisecondsSinceEpoch;
//       timeStep = time - previousTime;
//       previousTime = time;
//     }

//     sumTime += timeStep;
//     numNotify++;
//     var avgTime = sumTime / numNotify;
//     var avgTime2 = avgTime.floor();
//     print(
//         "{$tag}{$logId} Received notify: (length: ${data.length}) firist:${data[0]} from peripheral cast:{$timeStep}ms avg:{$avgTime2}ms");
//   }, onError: (dynamic error) {
//     print("receive data error $error");
//   });
//   print("Write with response start");
//   characteristic = QualifiedCharacteristic(
//       serviceId: service,
//       characteristicId: BleUUIDs.baseWriteTest,
//       deviceId: device.id);
//   await flutterReactiveBle
//       .writeCharacteristicWithResponse(characteristic, value: [0x00]);
//   print("Write with response complete");
// }
Future<void> runSampleCase(BleManager bleManager) async {
  bleLog(tag, "Creating sample case");
  // CaseBase sampleCase = VerifyCentralCase();
  // CaseBase sampleCase = ReconnectCase();
  CaseBase sampleCase = BleCommunicationCase(logId: 1);
  // CaseBase sampleCase2 = BleCommunicationCase(logId: 2);
  // CaseBase sampleCase = BleexRequestCase();
  // CaseBase sampleCase = BleexRequestHighFrequencyCase();
  // CaseBase sampleCase = BleexCommunicationCase();
  // CaseBase sampleCase = ConnectByDistCase();
  // CaseBase sampleCase = ScanCase();

  sampleCase.init(bleManager);
  // sampleCase2.init(bleManager);
  bleLog(tag, "Sample case created");
  await sampleCase.start(service: BleUUIDs.service);
  // await Future.delayed(Duration(milliseconds: 5000));
  // await sampleCase2.start(service: BleUUIDs.service2);
}
