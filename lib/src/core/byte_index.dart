part of ble_ex;

Map<String, int> _indexMap = {};
int _getIndex(String type) {
  int existIndex = 0;
  if (_indexMap.containsKey(type)) {
    existIndex = _indexMap[type]!;
  }
  existIndex++;
  if (existIndex == 256) {
    existIndex = 0;
  }
  _indexMap[type] = existIndex;
  return existIndex;
}
