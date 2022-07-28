library ble_ex;

import 'dart:math';
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:ble_ex/src/ble_log_level.dart';
import 'package:ble_ex/src/ble_logger.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

part 'ble_device_core.dart';
part 'ble_device.dart';

part 'helpers/ble_device_request.dart';
part 'helpers/ble_device_bytes_request.dart';
part 'helpers/ble_device_notify.dart';
part 'helpers/ble_device_write.dart';
part 'helpers/ble_device_receive.dart';
part 'helpers/ble_device_mtu.dart';

part 'core/byte_index.dart';

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

/// 封装后的Ble外围设备管理器
class BleManager extends Object {
  static const String _tag = "BleManager";

  static int logLevel = BleLogLevel.none;

  final FlutterReactiveBle _flutterReactiveBle = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _subscription;

  final Map _deviceMapCache = <String, DiscoveredDevice>{};
  final Map _deviceMap = <String, DiscoveredDevice>{};
  final Map _updateDeviceMap = <String, DiscoveredDevice>{};
  _BleStatusIniter? _statusIniter;
  Timer? _scanTimer;
  Uint8List? _manufacturerFilter;

  void scanDevices({Uint8List? manufacturerFilter}) async {
    _doScanDevices(true);
  }

  void _doScanDevices(bool fire, {Uint8List? manufacturerFilter}) async {
    _manufacturerFilter = manufacturerFilter;
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
    if (_manufacturerFilter != null) {
      if (!_compareManufacturerData(device, _manufacturerFilter!)) {
        return;
      }
    }
    _checkTargetUuidDevice(device);
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

  void stopScanDevices() {
    fireScanEvent = false;
    _targetServiceUuid = null;
    _targetManufacturerData = null;
    _findTargetDeviceFunc = null;

    _manufacturerFilter = null;

    _deviceMap.clear();
    _deviceMapCache.clear();
    _updateDeviceMap.clear();

    if (_statusIniter != null) {
      _statusIniter!.cancel();
    }
    _statusIniter = null;
    if (_scanTimer != null) {
      _scanTimer!.cancel();
    }
    _scanTimer = null;
    if (_subscription != null) {
      _subscription!.cancel();
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

  Uuid? _targetServiceUuid;
  Uint8List? _targetManufacturerData;
  void Function(DiscoveredDevice device)? _findTargetDeviceFunc;
  void _checkTargetUuidDevice(DiscoveredDevice device) {
    if (device.serviceUuids.isNotEmpty) {
      for (var uuid in device.serviceUuids) {
        if (_targetServiceUuid != null && uuid == _targetServiceUuid) {
          if (_targetManufacturerData == null) {
            if (_findTargetDeviceFunc != null) {
              _findTargetDeviceFunc!(device);
            }
          } else if (_compareManufacturerData(
              device, _targetManufacturerData!)) {
            if (_findTargetDeviceFunc != null) {
              _findTargetDeviceFunc!(device);
            }
          }
        }
      }
    }
  }

  bool _compareManufacturerData(
      DiscoveredDevice device, Uint8List targetManufacturerData) {
    Uint8List curManufacturerData = device.manufacturerData;
    if (curManufacturerData.length - 2 >= targetManufacturerData.length) {
      for (int i = 0; i < targetManufacturerData.length; i++) {
        if (curManufacturerData[i + 2] != targetManufacturerData[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  /// 得到目标蓝牙服务
  Future<DiscoveredDevice> scanForDevice(Uuid serviceUuid,
      {Uint8List? manufacturerFilter}) {
    stopScanDevices();
    fireScanEvent = false;
    Completer<DiscoveredDevice> _completer = Completer();
    _targetServiceUuid = serviceUuid;
    _targetManufacturerData = manufacturerFilter;
    _findTargetDeviceFunc = (device) {
      stopScanDevices();
      _completer.complete(device);
    };
    _doScanDevices(false);
    return _completer.future;
  }

  /// 创建一个外围设备服务
  BlePeripheralService createPeripheralService(
      DiscoveredDevice device, Uuid serviceUuid) {
    return BlePeripheralService._(device.id, serviceUuid, _flutterReactiveBle);
  }

  /// 创建一个外围设备
  BlePeripheral createPeripheral(DiscoveredDevice device) {
    return BlePeripheral._(device.id, _flutterReactiveBle, null);
  }
}
