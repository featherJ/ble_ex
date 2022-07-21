import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/ble_uuids.dart';
import 'package:ble_ex_example/samples/constants.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class CaseBase {
  static const String tag = "CaseBase";

  late BleManager bleManager;
  void init(BleManager bleManager) {
    this.bleManager = bleManager;
  }

  late BlePeripheralService peripheral;
  Future<void> start() async {
    var device = await bleManager.scanForDevice(BleUUIDs.service,
        manufacturerFilter: Constants.serviceManufacturerTag);
    bleLog(tag, 'Find device: ' + device.toString());
    peripheral = createPeripheral(device, BleUUIDs.service);
    peripheral.connect();
  }

  BlePeripheralService createPeripheral(
      DiscoveredDevice device, Uuid serviceId) {
    BlePeripheralService peripheral =
        bleManager.createPeripheralService(device, serviceId);
    peripheral.addConnectedListener(connectedHandler);
    peripheral.addDisconnectedListener(disconnectedHandler);
    peripheral.addConnectErrorListener(connectErrorHandler);
    return peripheral;
  }

  void connectedHandler(dynamic target) {
    bleLog(tag, "Connected to service");
  }

  void disconnectedHandler(dynamic target) {
    bleLog(tag, "Disonnected from service");
  }

  void connectErrorHandler(dynamic target, Object error) {
    bleLog(tag, "Connect error ${error.toString()}");
  }
}
