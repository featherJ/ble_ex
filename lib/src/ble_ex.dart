library ble_ex;

import 'package:ble_ex/ble_ex.dart';

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

part 'scan/commons.dart';
part 'scan/scanning_task.dart';
part 'scan/searching_task.dart';
part 'consts/data_tags.dart';
part 'core/byte_index.dart';
part 'device/ble_peripheral_core.dart';
part 'device/ble_peripheral.dart';
part 'helpers/large_writer.dart';
part 'helpers/notify_data.dart';
part 'helpers/requester.dart';
part 'helpers/suggest_mtu_requester.dart';
part 'helpers/large_indicate_recever.dart';
part 'helpers/large_requester.dart';

class _BleStatusIniter {
  void Function()? onFinished;
  FlutterReactiveBle? _flutterReactiveBle;
  _BleStatusIniter(this._flutterReactiveBle);

  List<void Function()> initedCallbacks = [];
  void addInitedListener(void Function() initedCallback) {
    initedCallbacks.add(initedCallback);
  }

  bool _canceled = false;
  StreamSubscription<BleStatus>? subscription;
  void initStatus() async {
    if (_flutterReactiveBle == null) {
      return;
    }
    _flutterReactiveBle!.initialize().then((value) {
      if (_flutterReactiveBle!.status == BleStatus.ready) {
        if (_canceled) {
          _doFinised();
          return;
        }
        _doInited();
        _doFinised();
        dispose();
      } else {
        subscription = _flutterReactiveBle!.statusStream.listen((status) {
          if (status == BleStatus.ready) {
            if (subscription != null) {
              subscription!.cancel();
            }
            if (_canceled) {
              _doFinised();
              return;
            }
            _doInited();
            _doFinised();
            dispose();
          }
        });
      }
    });
  }

  void _doInited() {
    for (var initedCallback in initedCallbacks) {
      initedCallback();
    }
  }

  void _doFinised() {
    if (onFinished != null) {
      onFinished!();
    }
  }

  void cancel() {
    _canceled = true;
    _doFinised();
    dispose();
  }

  void dispose() {
    subscription?.cancel();
    subscription = null;
    initedCallbacks.clear();
    _flutterReactiveBle = null;
    onFinished = null;
  }
}

/// 封装后的Ble外围设备管理器
class BleEx extends Object {
  static final BleEx _sharedInstance = BleEx._();

  static int _logLevel = BleLogLevel.none;
  static int get logLevel => _logLevel;
  static set logLevel(int value) {
    _logLevel = value;
    _sharedInstance._setLogLevel(value);
  }

  factory BleEx() => _sharedInstance;

  late FlutterReactiveBle _flutterReactiveBle;
  late _BleScannerHelper _scannerHelper;
  BleEx._() {
    _flutterReactiveBle = FlutterReactiveBle();
    _scannerHelper = _BleScannerHelper(this, _flutterReactiveBle);
    _setLogLevel(logLevel);
  }

  void _setLogLevel(int value) {
    if (value & BleLogLevel.none == 0) {
      _flutterReactiveBle.logLevel = LogLevel.none;
    } else if (value & BleLogLevel.system != 0) {
      _flutterReactiveBle.logLevel = LogLevel.verbose;
    } else {
      _flutterReactiveBle.logLevel = LogLevel.none;
    }
  }

  /// 蓝牙状态
  static Future<BleStatus> getStatus() => _sharedInstance._getStatus();

  Future<BleStatus> _getStatus() async {
    if (_flutterReactiveBle.status != BleStatus.unknown) {
      return _flutterReactiveBle.status;
    } else {
      StreamSubscription<BleStatus>? subscription;
      Completer<BleStatus> completer = Completer();
      subscription = _flutterReactiveBle.statusStream.listen((status) {
        if (status != BleStatus.unknown) {
          if (subscription != null) {
            subscription.cancel();
          }
          completer.complete(status);
        }
      });
      return completer.future;
    }
  }

  _BleStatusIniter? _statusIniter;
  Future<void> ensureInited() async {
    //尽可能将多次的 ensureInited 合并成一个异步请求
    Completer completer = Completer();
    if (_statusIniter == null) {
      _statusIniter = _BleStatusIniter(_flutterReactiveBle);
      _statusIniter!.onFinished = () {
        _statusIniter?.dispose();
        _statusIniter = null;
      };
      _statusIniter!.initStatus();
    }
    _statusIniter!.addInitedListener(completer.complete);
    return completer.future;
  }

  /// 创建一个设备扫描任务
  BleScanningTask createScanningTask() {
    return BleScanningTask._(_scannerHelper);
  }

  /// 搜索指定设备
  Future<DiscoveredDevice?> searchForDevice(List<DevicesFilter> filters,
      {Duration timeout = const Duration(milliseconds: 5000)}) async {
    BleSearchingTask task = BleSearchingTask._(_scannerHelper);
    return task.searchForDevice(filters, timeout);
  }

  /// 创建一个外围设备
  T createPeripheral<T extends BlePeripheral>(
      DiscoveredDevice device, T instance) {
    instance._initPeripheral(device.id, _flutterReactiveBle);
    return instance;
  }
}
