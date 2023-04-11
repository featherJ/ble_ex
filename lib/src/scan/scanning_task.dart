part of ble_ex;

/// 扫描任务
class BleScanningTask {
  _BleScannerHelper? _scannerHelper;
  final List<DevicesFilter> _filters = [];
  final List<ScanningListener> _deviceUpdateCallbacks = [];

  BleScanningTask._(this._scannerHelper);

  /// 添加一个设备更新监听
  void addDeviceUpdateListener(ScanningListener listener) {
    _deviceUpdateCallbacks.add(listener);
  }

  /// 移除一个设备更新监听
  void removeDeviceUpdateListener(ScanningListener listener) {
    _deviceUpdateCallbacks.remove(listener);
  }

  /// 开始扫描设备
  void scanDevices({List<DevicesFilter>? filters}) {
    if (_disposed) {
      throw Exception("Scanning task can not start after disposed");
    }
    _filters.clear();
    if (filters != null) {
      for (var i = 0; i < filters.length; i++) {
        _filters.add(filters[i]);
      }
    }
    _scannerHelper!.addDeviceUpdateListener(_deviceUpdateHandler);
  }

  /// 停止扫描设备，停止后可以重新开启
  void stopScan() {
    _scannerHelper?.removeDeviceUpdateListener(_deviceUpdateHandler);
  }

  void _deviceUpdateHandler(DiscoveredDevice device) {
    for (var filter in _filters) {
      if (!filter(device)) {
        return;
      }
    }
    for (var deviceUpdateCallback in _deviceUpdateCallbacks) {
      deviceUpdateCallback(device);
    }
  }

  bool _disposed = false;
  bool get disposed => _disposed;

  /// 释放，释放后则不能在开启
  void dispose() {
    stopScan();
    _filters.clear();
    _deviceUpdateCallbacks.clear();
    _disposed = true;
    _scannerHelper = null;
  }
}
