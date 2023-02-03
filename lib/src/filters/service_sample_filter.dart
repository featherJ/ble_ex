import 'package:ble_ex/ble_ex.dart';

class ServiceSampleFilter {
  final Uuid service;
  ServiceSampleFilter(this.service);
  DevicesFilter? _filter;
  DevicesFilter get filter {
    _filter ??= (device) {
      if (device.serviceUuids.isNotEmpty) {
        for (var uuid in device.serviceUuids) {
          if (uuid == service) {
            return true;
          }
        }
      }
      return false;
    };
    return _filter!;
  }
}
