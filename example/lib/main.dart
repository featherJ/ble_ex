import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/cases/base_case.dart';
import 'package:ble_ex_example/samples/cases/scan_case.dart';
import 'package:flutter/material.dart';

const String tag = "Main";
void main() async {
  BleEx.logLevel = BleLogLevel.lib;
  WidgetsFlutterBinding.ensureInitialized();
  bleLog(tag, "Running");
  var bleex = BleEx();
  runSampleCase(bleex);
}

void runSampleCase(BleEx bleex) {
  bleLog(tag, "Creating sample case");
  // CaseBase sampleCase = VerifyCentralCase();
  // CaseBase sampleCase = ReconnectCase();
  // CaseBase sampleCase = BleCommunicationCase();
  // CaseBase sampleCase = BleexRequestCase();
  // CaseBase sampleCase = BleexRequestHighFrequencyCase();
  // CaseBase sampleCase = BleexCommunicationCase();
  // CaseBase sampleCase = ConnectByDistCase();
  CaseBase sampleCase = ScanCase();

  sampleCase.init(bleex);
  bleLog(tag, "Sample case created");
  sampleCase.start();
}
