part of ble_ex;

/// 封装后的Ble外围设备核心
class _BlePeripheralCore {
  static const String _tag = "BlePeripheralCore";

  //重试次数
  static const int _retryTimes = 2;

  final String _deviceId;
  FlutterReactiveBle? _flutterReactiveBle;
  _BlePeripheralCore._(this._deviceId, this._flutterReactiveBle);

  /// 设备id
  String get deviceId => _deviceId;
  StreamSubscription<ConnectionStateUpdate>? _connection;

  ///当前状态
  Stream<ConnectionStateUpdate> get state => _deviceConnectionController.stream;
  final _deviceConnectionController = StreamController<ConnectionStateUpdate>();
  Timer? connectTimer;

  DeviceConnectionState _previousState = DeviceConnectionState.disconnected;

  bool _connected = false;
  bool _connecting = false;

  /// 当前是否是已连接状态
  bool get connected => _connected;

  /// 是否在连接中
  bool get connecting => _connecting;

  void connect({int timeoutMilliseconds = 2000}) {
    if (connecting) {
      bleLog(_tag, '[Warning] Can not run connect again');
      return;
    }
    _doConnect(timeoutMilliseconds, 0);
  }

  Future<void> _doConnect(int timeoutMilliseconds, int retryTimes) async {
    if (_disposed) {
      throw Exception("Can not call this after disposed");
    }
    _disconnected = false;
    _connecting = true;
    bool connected = false;
    bool timeout = false;
    await _cancelCurrent();
    await _clearGattCache();
    _connection = _flutterReactiveBle!
        .connectToDevice(
            id: deviceId,
            servicesWithCharacteristicsToDiscover: null,
            connectionTimeout: Duration(milliseconds: timeoutMilliseconds))
        .listen((update) async {
      if (!timeout) {
        bleLog(_tag,
            'ConnectionState for device $deviceId : ${update.connectionState}');
        if (update.connectionState == DeviceConnectionState.disconnected) {
          connectTimer?.cancel();
          await _cancelCurrent();
          await _clearGattCache();
          if (retryTimes < _retryTimes) {
            //重试
            bleLog(_tag, 'Retry doConnect $retryTimes');
            _doConnect(timeoutMilliseconds, retryTimes + 1);
          } else {
            _connecting = false;
            _updateState(update);
          }
        } else if (update.connectionState == DeviceConnectionState.connected) {
          _connecting = false;
          //避免连接成功之后再次断开连接进入首次连接的重试
          retryTimes = _retryTimes;
          connected = true;
          connectTimer?.cancel();
          _updateState(update);
        } else {
          _updateState(update);
        }
      }
    }, onError: (Object e) {
      _connecting = false;
      connectTimer?.cancel(); // 取消定时器
      bleLog(_tag, 'Connecting to device $deviceId resulted in error $e');
      _updateError(e);
    });

    connectTimer?.cancel(); // 取消定时器
    connectTimer = Timer.periodic(Duration(milliseconds: timeoutMilliseconds),
        (timer) async {
      timer.cancel();
      if (!connected) {
        bleLog(_tag, 'Connecting to device $deviceId timeout');
        timeout = true;
        if (retryTimes < _retryTimes) {
          //重试
          bleLog(_tag, 'Retry doConnect $retryTimes');
          _doConnect(timeoutMilliseconds, retryTimes + 1);
        } else {
          _connecting = false;
          connectTimer?.cancel();
          _updateError("Connect Time out");
        }
      }
    });
  }

  void connectToAdvertisingDevice(Uuid serviceId,
      {int timeoutMilliseconds = 2000}) {
    if (connecting) {
      bleLog(_tag, '[Warning] Can not run connect again');
      return;
    }
    _doConnectToAdvertisingDevice(serviceId, timeoutMilliseconds, 0);
  }

  Future<void> _doConnectToAdvertisingDevice(
      Uuid serviceId, int timeoutMilliseconds, int retryTimes) async {
    if (_disposed) {
      throw Exception("Can not call this after disposed");
    }
    _connecting = true;
    bool connected = false;
    bool timeout = false;
    await _cancelCurrent();
    await _clearGattCache();
    _connection = _flutterReactiveBle!
        .connectToAdvertisingDevice(
            id: deviceId,
            withServices: [serviceId],
            prescanDuration: Duration(milliseconds: timeoutMilliseconds))
        .listen((update) async {
      if (!timeout) {
        bleLog(_tag,
            'ConnectionState for device $deviceId : ${update.connectionState}');
        if (update.connectionState == DeviceConnectionState.disconnected) {
          connectTimer?.cancel();
          await _cancelCurrent();
          await _clearGattCache();
          if (retryTimes < _retryTimes) {
            //重试
            bleLog(_tag, 'Retry doConnect $retryTimes');
            _doConnectToAdvertisingDevice(
                serviceId, timeoutMilliseconds, retryTimes + 1);
          } else {
            _connecting = false;
            _updateState(update);
          }
        } else if (update.connectionState == DeviceConnectionState.connected) {
          _connecting = false;
          retryTimes = _retryTimes;
          connected = true;
          connectTimer?.cancel();
          _updateState(update);
        } else {
          _updateState(update);
        }
      }
    }, onError: (Object e) {
      _connecting = false;
      connectTimer?.cancel(); // 取消定时器
      bleLog(_tag, 'Connecting to device $deviceId resulted in error $e');
      _updateError(e);
    });

    connectTimer?.cancel(); // 取消定时器
    connectTimer = Timer.periodic(Duration(milliseconds: timeoutMilliseconds),
        (timer) async {
      timer.cancel();
      if (!connected) {
        bleLog(_tag, 'Connecting to device $deviceId timeout');
        timeout = true;
        if (retryTimes < _retryTimes) {
          //重试
          bleLog(_tag, 'Retry doConnect $retryTimes');
          _doConnectToAdvertisingDevice(
              serviceId, timeoutMilliseconds, retryTimes + 1);
        } else {
          _connecting = false;
          connectTimer?.cancel();
          _updateError("Connect Time out");
        }
      }
    });
  }

  Future<void> _clearGattCache() async {
    if (Platform.isAndroid) {
      try {
        await _flutterReactiveBle?.clearGattCache(_deviceId);
        // ignore: empty_catches
      } catch (e) {}
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _cancelCurrent() async {
    try {
      await _connection?.cancel();
      // ignore: empty_catches
    } catch (e) {
      bleLog(_tag, 'Error disconnecting from a device: $e');
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }

  bool _disconnected = false;

  /// 是否已经断开连接
  bool get disconnected => _disconnected;
  Future<void> disconnect() async {
    _connecting = false;
    _disconnected = true;
    bool previousConnected = connected;
    _connected = false;
    if (previousConnected) {
      _updateState(ConnectionStateUpdate(
        deviceId: deviceId,
        connectionState: DeviceConnectionState.disconnecting,
        failure: null,
      ));
    }
    connectTimer?.cancel();
    bleLog(_tag, 'disconnecting to device: $deviceId');
    await _cancelCurrent();
    await _clearGattCache();
    await Future.delayed(const Duration(milliseconds: 100));
    if (previousConnected) {
      _updateState(ConnectionStateUpdate(
        deviceId: deviceId,
        connectionState: DeviceConnectionState.disconnected,
        failure: null,
      ));
    }
  }

  /// 向一个 characteristic 写入数据数据
  Future<void> writeCharacteristicWithResponse(
      Uuid serviceId, Uuid characteristicId, Uint8List data) async {
    if (disposed || disconnected) {
      throw Exception("Can not call this after disposed or disconnected");
    }
    final characteristic = QualifiedCharacteristic(
        serviceId: serviceId,
        characteristicId: characteristicId,
        deviceId: deviceId);
    List<int> value = data.toList();
    await _flutterReactiveBle!
        .writeCharacteristicWithResponse(characteristic, value: value);
  }

  /// 向一个 characteristic 写入无应答数据数据
  Future<void> writeCharacteristicWithoutResponse(
      Uuid serviceId, Uuid characteristicId, Uint8List data) async {
    if (disposed || disconnected) {
      throw Exception("Can not call this after disposed or disconnected");
    }
    final characteristic = QualifiedCharacteristic(
        serviceId: serviceId,
        characteristicId: characteristicId,
        deviceId: deviceId);
    List<int> value = data.toList();
    await _flutterReactiveBle!
        .writeCharacteristicWithoutResponse(characteristic, value: value);
  }

  /// 从指定的 characteristic 读取数据
  Future<Uint8List> readCharacteristic(
      Uuid serviceId, Uuid characteristicId) async {
    if (disposed || disconnected) {
      throw Exception("Can not call this after disposed or disconnected");
    }
    final characteristic = QualifiedCharacteristic(
        serviceId: serviceId,
        characteristicId: characteristicId,
        deviceId: deviceId);
    List<int> result =
        await _flutterReactiveBle!.readCharacteristic(characteristic);
    return Uint8List.fromList(result);
  }

  ///监听一个指定的 characteristic
  Stream<Uint8List> subscribeToCharacteristic(
      Uuid serviceId, Uuid characteristicId) {
    if (disposed || disconnected) {
      throw Exception("Can not call this after disposed or disconnected");
    }
    final characteristic = QualifiedCharacteristic(
        serviceId: serviceId,
        characteristicId: characteristicId,
        deviceId: deviceId);
    return _flutterReactiveBle!
        .subscribeToCharacteristic(characteristic)
        .map((value) => Uint8List.fromList(value));
  }

  /// 请求优先级，仅在android上生效
  Future<void> requestConnectionPriority(ConnectionPriority priority) async {
    if (disposed || disconnected) {
      throw Exception("Can not call this after disposed or disconnected");
    }
    if (Platform.isAndroid) {
      return _flutterReactiveBle!
          .requestConnectionPriority(deviceId: deviceId, priority: priority);
    }
  }

  /// 请求修改mtu
  Future<int> requestMtu(int mtu, {int timeout = 2000}) async {
    if (disposed || disconnected) {
      throw Exception("Can not call this after disposed or disconnected");
    }
    bool isTimeout = false;
    bool callback = false;
    Completer<int> completer = Completer();
    var timer = Timer.periodic(Duration(milliseconds: timeout), (timer) {
      timer.cancel();
      isTimeout = true;
      if (!callback) {
        callback = true;
        completer.completeError(408);
      }
    });
    _flutterReactiveBle!.requestMtu(deviceId: deviceId, mtu: mtu).then((mtu) {
      if (!isTimeout) {
        timer.cancel();
        if (!callback) {
          callback = true;
          if (mtu > 1) {
            completer.complete(mtu);
          } else {
            completer.completeError(mtu);
          }
        }
      }
    }, onError: (e) {
      if (!isTimeout) {
        timer.cancel();
        if (!callback) {
          callback = true;
          completer.completeError(0);
        }
      }
    });
    return completer.future;
  }

  void _updateState(ConnectionStateUpdate state) {
    if (state.connectionState != _previousState) {
      //避免在已连接状态下依旧抛出连接中的事件
      if (_previousState == DeviceConnectionState.connected &&
          state.connectionState == DeviceConnectionState.connecting) {
      } else if (_previousState == DeviceConnectionState.disconnecting &&
          state.connectionState == DeviceConnectionState.connecting) {
      } else {
        if (state.connectionState == DeviceConnectionState.connected) {
          _connected = true;
        } else if (state.connectionState ==
            DeviceConnectionState.disconnected) {
          _connected = false;
        }
        _previousState = state.connectionState;
        _deviceConnectionController.add(state);
      }
    }
  }

  void _updateError(Object error) {
    _deviceConnectionController.addError(error);
  }

  bool _disposed = false;

  ///是否已释放
  bool get disposed => _disposed;
  Future<void> dispose() async {
    _connecting = false;
    _disposed = true;
    _connected = false;
    await disconnect();
    await _deviceConnectionController.close();
    _flutterReactiveBle = null;
  }
}
