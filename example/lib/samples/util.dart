import 'dart:math';

Map<String, List<int>> rssiMap = {};

/// calculate dist by rssi
num calcDistByRSSI(String address, int rssi) {
  late List<int> rssiList;
  if (rssiMap.containsKey(address)) {
    rssiList = rssiMap[address]!;
  } else {
    rssiList = [];
    rssiMap[address] = rssiList;
  }
  rssiList.add(rssi);
  if (rssiList.length > 4) {
    rssiList.removeAt(0);
  }
  num rssiAvg = 0;
  for (var value in rssiList) {
    rssiAvg += value;
  }
  rssiAvg = rssiAvg / rssiList.length;
  num iRssi = rssiAvg.abs();
  num power = (iRssi - 70) / (10 * 2);
  return pow(10.0, power);
}
