import 'dart:typed_data';

import 'package:ble_ex/src/ble_ex.dart';

class ManufacturerSampleFilter {
  final Uint8List matchData;
  ManufacturerSampleFilter(this.matchData);
  DevicesFilter? _filter;
  DevicesFilter get filter {
    _filter ??= (device) {
      Uint8List curData = device.manufacturerData;
      if (curData.length - 2 >= matchData.length) {
        for (int i = 0; i < matchData.length; i++) {
          if (curData[i + 2] != matchData[i]) {
            return false;
          }
        }
        return true;
      }
      return false;
    };
    return _filter!;
  }
}
