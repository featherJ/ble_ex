import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/ble_uuids.dart';
import 'package:ble_ex_example/samples/constants.dart';

class CaseBase {
  static const String tag = "CaseBase";
  late BleEx bleex;
  void init(BleEx bleex) {
    this.bleex = bleex;
  }

  late BlePeripheral peripheral;
  Future<void> start() async {
    var device = await bleex.lookForDevice([
      ServiceSampleFilter(BleUUIDs.service1).filter,
      ManufacturerSampleFilter(Constants.serviceManufacturerTag).filter
    ]);

    bleLog(tag, 'Find device: ' + device.toString());
    peripheral = createPeripheral(device);
    peripheral.connect();
  }

  BlePeripheral createPeripheral(DiscoveredDevice device) {
    BlePeripheral peripheral =
        bleex.createPeripheral<BlePeripheral>(device, BlePeripheral());
    peripheral.addConnectedListener(connectedHandler);
    peripheral.addDisconnectedListener(disconnectedHandler);
    peripheral.addConnectErrorListener(connectErrorHandler);
    return peripheral;
  }

  void connectedHandler(BlePeripheral target) {
    bleLog(tag, "Connected to service");
  }

  void disconnectedHandler(BlePeripheral target) {
    bleLog(tag, "Disonnected from service");
  }

  void connectErrorHandler(BlePeripheral target, Object error) {
    bleLog(tag, "Connect error ${error.toString()}");
  }
}
