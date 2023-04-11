part of ble_ex;

/// 搜索监听
typedef ScanningListener = void Function(DiscoveredDevice device);

/// 设备过滤器，用于搜索或查找
typedef DevicesFilter = bool Function(DiscoveredDevice device);

/// 该实例只有一个，用于多个搜索任务共用，以实现可以多个搜索进程同步存在
class _BleScannerHelper {
  static const String _tag = "_BleScannerHelper";

  final BleEx bleEx;
  final FlutterReactiveBle flutterReactiveBle;
  _BleScannerHelper(this.bleEx, this.flutterReactiveBle);

  StreamSubscription<DiscoveredDevice>? _subscription;

  bool startScan = false;
  bool scanning = false;
  void scan() async {
    if (startScan) return;
    startScan = true;
    await bleEx.ensureInited();
    //开启一个搜索之前一定要确保之前的搜索已经停止了，因为底层的搜索只能同时存在一个
    await _ensureStoped();
    if (!startScan) return; //有可能已被停止了
    if (scanning) return; //已经在扫描中了
    scanning = true;
    _subscription = flutterReactiveBle.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
    ).listen(
      (device) {
        List<ScanningListener> tempCallbacks = [];
        for (var func in deviceUpdateCallbacks) {
          tempCallbacks.add(func);
        }
        for (var callback in tempCallbacks) {
          callback(device);
        }
      },
      onError: (error) {
        bleLog(_tag, 'Scan error:${(error.toString())}');
      },
    );
    bleLog(_tag, 'scanning started.');
  }

  void stop() {
    startScan = false;
    _doStop();
  }

  bool stopping = false;
  void _doStop() async {
    if (stopping) {
      return;
    }
    stopping = true;
    if (_subscription != null) {
      scanning = false;
      await _subscription!.cancel();
      _subscription = null;
      await Future.delayed(const Duration(milliseconds: 200));
      bleLog(_tag, 'scanning stoped.');
    }
    for (var stopedCallback in stopedCallbacks) {
      stopedCallback();
    }
    stopedCallbacks.clear();
    stopping = false;
  }

  List<void Function()> stopedCallbacks = [];
  Future<void> _ensureStoped() async {
    Completer completer = Completer();
    stopedCallbacks.add(completer.complete);
    if (!stopping) {
      _doStop();
    }
    return completer.future;
  }

  List<ScanningListener> deviceUpdateCallbacks = [];

  /// 添加一个设备更新监听
  void addDeviceUpdateListener(ScanningListener listener) {
    deviceUpdateCallbacks.add(listener);
    _updateScanning();
  }

  /// 移除一个设备更新监听
  void removeDeviceUpdateListener(ScanningListener listener) {
    deviceUpdateCallbacks.remove(listener);
    _updateScanning();
  }

  void _updateScanning() {
    if (deviceUpdateCallbacks.isNotEmpty) {
      if (!startScan) {
        scan();
      }
    } else if (deviceUpdateCallbacks.isEmpty) {
      stop();
    }
  }
}
