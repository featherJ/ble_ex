library ble_ex;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ble_ex/ble_ex.dart';
import 'package:ble_ex/src/utils/ble_log_level.dart';
import 'package:ble_ex/src/utils/ble_logger.dart';

part 'device/ble_peripheral_core.dart';
part 'device/ble_peripheral.dart';

part 'helpers/mtu_helper.dart';
part 'helpers/notify_data.dart';

class _BleStatusIniter {
  final FlutterReactiveBle _flutterReactiveBle;
  _BleStatusIniter(this._flutterReactiveBle);

  bool _canceled = false;
  final _completer = Completer();
  Future<void> initStatus() async {
    _flutterReactiveBle.initialize().then((value) {
      if (_flutterReactiveBle.status == BleStatus.ready) {
        if (!_completer.isCompleted && !_canceled) {
          _completer.complete();
        }
      } else {
        _flutterReactiveBle.statusStream.listen((status) {
          if (status == BleStatus.ready) {
            if (!_completer.isCompleted && !_canceled) {
              _completer.complete();
            }
          }
        });
      }
    });
    return _completer.future;
  }

  void cancel() {
    _canceled = true;
  }
}

/// 设备过滤器，用于搜索或查找
typedef DevicesFilter = bool Function(DiscoveredDevice device);

/// 封装后的Ble外围设备管理器
class BleEx extends Object {
  static const String _tag = "BleEx";
  static int logLevel = BleLogLevel.none;

  final FlutterReactiveBle _flutterReactiveBle = FlutterReactiveBle();

  _BleStatusIniter? _statusIniter;
  StreamSubscription<DiscoveredDevice>? _subscription;
  final Map _deviceMapCache = <String, DiscoveredDevice>{};
  final Map _deviceMap = <String, DiscoveredDevice>{};
  final Map _updateDeviceMap = <String, DiscoveredDevice>{};

  List<DevicesFilter> _scanfilters = [];
  Timer? _scanTimer;

  /// 搜索设备
  void scanDevices({List<DevicesFilter>? scanfilters}) async {
    await stopScanDevices();
    _doScanDevices(true, scanfilters);
  }

  void _doScanDevices(bool fire, List<DevicesFilter>? scanfilters) async {
    _scanfilters = [];
    if (scanfilters != null) {
      for (var i = 0; i < scanfilters.length; i++) {
        _scanfilters.add(scanfilters[i]);
      }
    }

    _deviceMapCache.clear();
    _deviceMap.clear();
    _updateDeviceMap.clear();
    if (logLevel & BleLogLevel.none == 0) {
      _flutterReactiveBle.logLevel = LogLevel.none;
    } else if (logLevel & BleLogLevel.system != 0) {
      _flutterReactiveBle.logLevel = LogLevel.verbose;
    } else {
      _flutterReactiveBle.logLevel = LogLevel.none;
    }
    _statusIniter = _BleStatusIniter(_flutterReactiveBle);
    await _statusIniter!.initStatus();
    fireScanEvent = fire;
    _subscription = _flutterReactiveBle.scanForDevices(
        withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
      _updateDevice(device);
    }, onError: (error) {
      if (logLevel & BleLogLevel.none == 0 && logLevel & BleLogLevel.lib != 0) {
        bleLog(_tag, 'Scan error:${(error.toString())}');
      }
    });
    _scanTimer =
        Timer.periodic(const Duration(milliseconds: 10000), _scanDelayHandler);
  }

  /// 是否过滤掉较弱的设备，且派发删除事件
  bool filterOutWeakDevice = false;

  void _scanDelayHandler(Timer timer) {
    if (!filterOutWeakDevice) {
      return;
    }
    if (_deviceMapCache.isNotEmpty) {
      _deviceMapCache.forEach((deviceId, device) {
        if (!_deviceMap.containsKey(deviceId)) {
          _updateDeviceMap.remove(deviceId);
          if (fireScanEvent) {
            List<void Function(DiscoveredDevice)> curScanRemoveDeviceFuncs = [];
            for (var listener in _scanRemoveDeviceFuncs) {
              curScanRemoveDeviceFuncs.add(listener);
            }
            for (var listener in curScanRemoveDeviceFuncs) {
              listener(device);
            }
          }
        }
      });
    }
    _deviceMapCache.clear();
    _deviceMap.forEach((deviceId, device) {
      _deviceMapCache[deviceId] = device;
    });
    _deviceMap.clear();
  }

  void _updateDevice(DiscoveredDevice device) {
    //如果存在通过 manufacturer 的过滤，则进行过滤
    for (var filter in _scanfilters) {
      if (!filter(device)) {
        return;
      }
    }
    _checkDeviceLookingFor(device);
    _deviceMap[device.id] = device;
    _doUpdateDevice(device);
  }

  void _doUpdateDevice(DiscoveredDevice device) {
    if (fireScanEvent) {
      if (_updateDeviceMap.containsKey(device.id)) {
        List<void Function(DiscoveredDevice)> curScanUpdateDeviceFuncs = [];
        for (var listener in _scanUpdateDeviceFuncs) {
          curScanUpdateDeviceFuncs.add(listener);
        }
        for (var listener in curScanUpdateDeviceFuncs) {
          listener(device);
        }
      } else {
        List<void Function(DiscoveredDevice)> curScanAddDeviceFuncs = [];
        for (var listener in _scanAddDeviceFuncs) {
          curScanAddDeviceFuncs.add(listener);
        }
        for (var listener in curScanAddDeviceFuncs) {
          listener(device);
        }
      }
    }
    _updateDeviceMap[device.id] = device;
  }

  /// 停止搜索设备
  Future<void> stopScanDevices() async {
    fireScanEvent = false;

    _findTargetDeviceFunc = null;
    _lookFilters = [];
    _scanfilters = [];

    _deviceMap.clear();
    _deviceMapCache.clear();
    _updateDeviceMap.clear();

    if (_statusIniter != null) {
      _statusIniter!.cancel();
      _statusIniter = null;
    }
    _statusIniter = null;
    if (_scanTimer != null) {
      _scanTimer!.cancel();
      _scanTimer = null;
    }
    _scanTimer = null;
    if (_subscription != null) {
      await _subscription!.cancel();
      _subscription = null;
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  /// 得到当前已经扫描到的所有设备
  List<DiscoveredDevice> get scannedDevices {
    List<DiscoveredDevice> deviceList = [];
    _updateDeviceMap.forEach((deviceId, device) {
      deviceList.add(device);
    });
    return deviceList;
  }

  bool fireScanEvent = true;
  final List<void Function(DiscoveredDevice device)> _scanAddDeviceFuncs = [];
  final List<void Function(DiscoveredDevice device)> _scanUpdateDeviceFuncs =
      [];
  final List<void Function(DiscoveredDevice device)> _scanRemoveDeviceFuncs =
      [];

  /// 扫描添加一个设备的监听
  void listenScanAddDevice(void Function(DiscoveredDevice device) listener) {
    _scanAddDeviceFuncs.add(listener);
  }

  /// 移除扫描添加一个设备的监听
  void unlistenScanAddDevice(void Function(DiscoveredDevice device) listener) {
    _scanAddDeviceFuncs.remove(listener);
  }

  /// 清空扫描添加设备的监听
  void clearScanAddDevice() {
    _scanAddDeviceFuncs.clear();
  }

  /// 扫描更新一个设备的监听
  void listenScanUpdateDevice(void Function(DiscoveredDevice device) listener) {
    _scanUpdateDeviceFuncs.add(listener);
  }

  /// 移除扫描更新一个设备的监听
  void unlistenScanUpdateDevice(
      void Function(DiscoveredDevice device) listener) {
    _scanUpdateDeviceFuncs.remove(listener);
  }

  /// 清空扫描更新设备的监听
  void clearScanUpdateDevice() {
    _scanUpdateDeviceFuncs.clear();
  }

  /// 扫描删除一个设备的监听
  void listenScanRemoveDevice(void Function(DiscoveredDevice device) listener) {
    _scanRemoveDeviceFuncs.add(listener);
  }

  /// 移除扫描删除一个设备的监听
  void unlistenScanRemoveDevice(
      void Function(DiscoveredDevice device) listener) {
    _scanRemoveDeviceFuncs.remove(listener);
  }

  /// 清空扫描删除设备的监听
  void clearScanRemoveDevice() {
    _scanRemoveDeviceFuncs.clear();
  }

  void Function(DiscoveredDevice device)? _findTargetDeviceFunc;
  void _checkDeviceLookingFor(DiscoveredDevice device) {
    if (_findTargetDeviceFunc != null && _lookFilters.isNotEmpty) {
      for (var filter in _lookFilters) {
        if (!filter(device)) {
          return;
        }
      }
      _findTargetDeviceFunc!(device);
    }
  }

  List<DevicesFilter> _lookFilters = [];

  /// 查找目标蓝牙服务
  Future<DiscoveredDevice> lookForDevice(List<DevicesFilter> filters) async {
    await stopScanDevices();
    fireScanEvent = false;
    Completer<DiscoveredDevice> _completer = Completer();
    _lookFilters = filters;
    _findTargetDeviceFunc = (device) async {
      await stopScanDevices();
      _completer.complete(device);
    };
    _doScanDevices(false, null);
    return _completer.future;
  }
}
