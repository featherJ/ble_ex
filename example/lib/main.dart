import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/cases/base_case.dart';
import 'package:ble_ex_example/samples/cases/ble_communication_case.dart';
import 'package:ble_ex_example/samples/cases/bleex_communication_case.dart';
import 'package:ble_ex_example/samples/cases/bleex_reqeust_case.dart';
import 'package:ble_ex_example/samples/cases/connect_by_dist_case.dart';
import 'package:ble_ex_example/samples/cases/reconnect_case.dart';
import 'package:ble_ex_example/samples/cases/scan_case.dart';
import 'package:ble_ex_example/samples/cases/verify_central_case.dart';
import 'package:flutter/material.dart';

const String tag = "Main";
void main() async {
  BleManager.logLevel = BleLogLevel.lib;
  WidgetsFlutterBinding.ensureInitialized();
  bleLog(tag, "Running");
  var bleManager = BleManager();
  runSampleCase(bleManager);
}

void runSampleCase(BleManager bleManager) {
  bleLog(tag, "Creating sample case");
  // CaseBase sampleCase = VerifyCentralCase();
  // CaseBase sampleCase = ReconnectCase();
  // CaseBase sampleCase = BleCommunicationCase();
  // CaseBase sampleCase = BleexRequestCase();
  // CaseBase sampleCase = BleexCommunicationCase();
  // CaseBase sampleCase = ConnectByDistCase();
  CaseBase sampleCase = ScanCase();

  sampleCase.init(bleManager);
  bleLog(tag, "Sample case created");
  sampleCase.start();
}
