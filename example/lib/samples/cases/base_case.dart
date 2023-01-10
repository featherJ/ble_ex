import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex_example/samples/constants.dart';

class CaseBase {
  static const String tag = "CaseBase";

  late BleManager bleManager;
  void init(BleManager bleManager) {
    this.bleManager = bleManager;
  }

  late BlePeripheralService peripheral;
  Future<void> start({required Uuid service}) async {
    var device = await bleManager.scanForDevice(service,
        manufacturerFilter: Constants.serviceManufacturerTag);
    bleLog(tag, 'Find device: ' + device.toString());
    peripheral = createPeripheral(device, service);
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
