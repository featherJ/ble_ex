import 'dart:typed_data';

import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/ble_uuids.dart';
import 'package:ble_ex_example/samples/cases/base_case.dart';
import 'package:ble_ex_example/samples/constants.dart';

class VerifyCentralCase extends CaseBase {
  static const String tag = "VerifyCentralCase";

  bool verifyCorrectFlag = false;
  bool verifyErrorFlag = false;
  @override
  Future<void> connectedHandler(BlePeripheral target) async {
    super.connectedHandler(target);
    bleLog(tag, " ---------------------------------- ");
    var verified = false;
    //Test verify correct
    if (!verifyCorrectFlag && !verified) {
      verified = true;
      verifyCorrectFlag = true;
      bleLog(tag, "------- Start verify correct test -------");
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
    }

    //Test verify error
    if (!verifyErrorFlag && !verified) {
      verified = true;
      verifyErrorFlag = true;
      bleLog(tag, "------- Start verify fail test -------");
      try {
        Uint8List verifyResult = await peripheral.request(BleUUIDs.service1,
            BleUUIDs.verifyCentral, Uint8List.fromList([0, 0, 0, 0]));
        if (verifyResult.isNotEmpty && verifyResult[0] == 1) {
          bleLog(tag, "verification succeeded");
        } else {
          bleLog(tag, "verification failed");
        }
      } catch (e) {
        bleLog(tag, "Verifying current device error ${e.toString()}");
      }
    }

    if (!verifyCorrectFlag || !verifyErrorFlag) {
      await Future.delayed(const Duration(milliseconds: 2000));
      await peripheral.disconnect();
      peripheral.connect();
    }
  }
}
