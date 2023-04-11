import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/cases/base_case.dart';
import 'package:ble_ex_example/samples/cases/ble_communication_case.dart';
import 'package:ble_ex_example/samples/cases/ble_mulit_write_case.dart';
import 'package:ble_ex_example/samples/cases/bleex_communication_case.dart';
import 'package:ble_ex_example/samples/cases/bleex_reqeust_case.dart';
import 'package:ble_ex_example/samples/cases/bleex_reqeust_high_frequency_case.dart';
import 'package:ble_ex_example/samples/cases/connect_by_dist_case.dart';
import 'package:ble_ex_example/samples/cases/reconnect_case.dart';
import 'package:ble_ex_example/samples/cases/scan_case.dart';
import 'package:ble_ex_example/samples/cases/verify_central_case.dart';
import 'package:flutter/material.dart';

const String tag = "Main";
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  BleEx.logLevel = BleLogLevel.lib;
  bleLog(tag, "Running");
  var bleex = BleEx();
  runSampleCase(bleex);
}

void runSampleCase(BleEx bleex) {
  bleLog(tag, "Creating sample case");
  // CaseBase sampleCase = VerifyCentralCase();
  // CaseBase sampleCase = BleMultiWriteCase();
  // CaseBase sampleCase = ReconnectCase();
  // CaseBase sampleCase = BleCommunicationCase();
  // CaseBase sampleCase = BleexRequestCase();
  // CaseBase sampleCase = BleexCommunicationCase();
  // CaseBase sampleCase = BleexRequestHighFrequencyCase();
  // CaseBase sampleCase = ConnectByDistCase();
  CaseBase sampleCase = ScanCase();

  sampleCase.init(bleex);
  bleLog(tag, "Sample case created");
  sampleCase.start();
}
