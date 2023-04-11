part of ble_ex;

/// 搜索任务
class BleSearchingTask {
  _BleScannerHelper? _scannerHelper;
  final List<DevicesFilter> _filters = [];
  BleSearchingTask._(this._scannerHelper);

  bool _disposed = false;
  bool get disposed => _disposed;
  Completer<DiscoveredDevice?> _completer = Completer();
  Timer? _searchTimer;

  /// 搜索指定设备
  Future<DiscoveredDevice?> searchForDevice(
      List<DevicesFilter> filters, Duration timeout) async {
    if (_disposed) {
      throw Exception("Searching task can not start after disposed");
    }
    _filters.clear();
    for (var i = 0; i < filters.length; i++) {
      _filters.add(filters[i]);
    }
    _completer = Completer();
    _scannerHelper!.addDeviceUpdateListener(_deviceUpdateHandler);
    _searchTimer = Timer(timeout, () {
      _searchTimer?.cancel();
      _searchTimer = null;
      if (!_completer.isCompleted) {
        _completer.complete(null);
        dispose();
      }
    });
    return _completer.future;
  }

  void _deviceUpdateHandler(DiscoveredDevice device) {
    for (var filter in _filters) {
      if (!filter(device)) {
        return;
      }
    }
    stopSearching();
    _completer.complete(device);
    dispose();
  }

  /// 停止扫描设备
  void stopSearching() {
    _searchTimer?.cancel();
    _searchTimer = null;
    _scannerHelper?.removeDeviceUpdateListener(_deviceUpdateHandler);
  }

  /// 释放
  void dispose() {
    stopSearching();
    _filters.clear();
    _disposed = true;
    _scannerHelper = null;
  }
}
