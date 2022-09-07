part of ble_ex;

/// 从设备
class BlePeripheral extends Object {
  static const String _tag = "BlePeripheral";

  late _MtuHelper _mtuHelper;
  late _WriteBytesHelper _writeBytesHelper;
  late _ReceiveBytesHelper _receiveBytesHelper;
  late _RequestBytesHelper _requestBytesHelper;

  /// 得到建议的mtu，-1表示为初始化
  int get suggestedMTU => _mtuHelper.suggestedMtu;

  /// 可发送的包的大小
  int get packageSize => _mtuHelper.packageSize;

  late BleDeviceCore _device;
  bool fireConnectEvent = true;

  dynamic _target;
  BlePeripheral._(
      String deviceId, FlutterReactiveBle flutterReactiveBle, dynamic target) {
    if (target == null) {
      _target = this;
    } else {
      _target = target;
    }
    _mtuHelper = _MtuHelper(this);
    _writeBytesHelper = _WriteBytesHelper(this);
    _receiveBytesHelper = _ReceiveBytesHelper(this);
    _requestBytesHelper = _RequestBytesHelper(this);
    _device = BleDeviceCore._(deviceId, flutterReactiveBle);
    _device.state.listen((event) {
      if (event.connectionState == DeviceConnectionState.connected) {
        bleLog(_tag, "Inner connected");
        _recoverNotifies();
        //内部连接成功的回调
        List<void Function()> curInnerConnectedFuncs = [];
        for (var func in _innerConnectedFuncs) {
          curInnerConnectedFuncs.add(func);
        }
        for (var listener in curInnerConnectedFuncs) {
          listener();
        }
        if (fireConnectEvent) {
          List<void Function(dynamic)> curConnectedListeners = [];
          for (var listener in _connectedListeners) {
            curConnectedListeners.add(listener);
          }
          for (var listener in curConnectedListeners) {
            listener(_target);
          }
        }
      }
      if (event.connectionState == DeviceConnectionState.disconnected) {
        bleLog(_tag, "Inner disconnected");
        _cancelNotifies();
        if (fireConnectEvent) {
          List<void Function(dynamic)> curDisconnectedListeners = [];
          for (var listener in _disconnectedListeners) {
            curDisconnectedListeners.add(listener);
          }
          for (var listener in curDisconnectedListeners) {
            listener(_target);
          }
        }
      }
    }, onError: (error) {
      bleLog(_tag, 'Inner error:${error.toString()}');
      List<void Function(dynamic, Object)> curConnectErrorListeners = [];
      for (var listener in _connectErrorListeners) {
        curConnectErrorListeners.add(listener);
      }
      for (var listener in curConnectErrorListeners) {
        listener(_target, error);
      }
    });
  }

  ///当前是否是已连接状态
  bool get connected => _device.connected;

  ///是否已释放
  bool get disposed => _device.disposed;

  /// 是否已经断开连接
  bool get disconnected => _device.disconnected;

  /// 是否在连接中
  bool get connecting => _device.connecting;

  ///恢复所有订阅
  Future<void> _recoverNotifies() async {
    bleLog(_tag, 'Recovering notify subscriptions');
    List<String> keys = notifyMap.keys.toList();
    for (var key in keys) {
      var notifyData = notifyMap[key]!;
      if (notifyData.streamSubscription == null) {
        bleLog(_tag,
            "Recovering serviceID:${notifyData.serviceId.toString()} characteristicId:${notifyData.characteristicId.toString()}");
        StreamSubscription<Uint8List> stream = _device
            .subscribeToCharacteristic(
                notifyData.serviceId, notifyData.characteristicId)
            .listen((data) {
          notifyData.callAll(_target, data);
        });
        notifyData.streamSubscription = stream;
      }
    }
    bleLog(_tag, 'Notifiy subscriptions recovered');
  }

  ///取消所有订阅
  Future<void> _cancelNotifies() async {
    bleLog(_tag, 'Canceling notifiy subscriptions');
    List<String> keys = notifyMap.keys.toList();
    for (var key in keys) {
      var notifyData = notifyMap[key];
      bleLog(_tag,
          'Canceling serviceID:${notifyData?.serviceId.toString()} characteristicId:${notifyData?.characteristicId.toString()}');
      await notifyData?.streamSubscription?.cancel();
      notifyData?.streamSubscription = null;
    }
    if (Platform.isIOS) {
      //TODO IOS有bug，cancel的回应没有等到就直接下一步了，所以这里手动延时下，看之后如何从底层直接修改掉这个问题。
      await Future.delayed(const Duration(milliseconds: 300));
    }
    bleLog(_tag, 'Notifiy subscriptions canceled');
  }

  ///释放所有订阅
  Future<void> _disposeNotifies() async {
    await _cancelNotifies();
    List<String> keys = notifyMap.keys.toList();
    for (var key in keys) {
      var notifyData = notifyMap[key];
      notifyData?.clear();
    }
    notifyMap.clear();
  }

  final List<void Function()> _innerConnectedFuncs = [];

  final List<void Function(dynamic)> _connectedListeners = [];
  final List<void Function(dynamic)> _disconnectedListeners = [];
  final List<void Function(dynamic, Object)> _connectErrorListeners = [];

  /// 添加已连接的监听
  void addConnectedListener(void Function(dynamic target) listener) {
    if (!_connectedListeners.contains(listener)) {
      _connectedListeners.add(listener);
    }
  }

  /// 移除已连接的监听
  void removeConnectedListener(void Function(dynamic target) listener) {
    if (_connectedListeners.contains(listener)) {
      _connectedListeners.remove(listener);
    }
  }

  /// 清空所有已连接监听
  void clearConnectedListener() {
    _connectedListeners.clear();
  }

  /// 添加断开连接的监听
  void addDisconnectedListener(void Function(dynamic target) listener) {
    if (!_disconnectedListeners.contains(listener)) {
      _disconnectedListeners.add(listener);
    }
  }

  /// 移除断开连接的监听
  void removeDisconnectedListener(void Function(dynamic target) listener) {
    if (_disconnectedListeners.contains(listener)) {
      _disconnectedListeners.remove(listener);
    }
  }

  /// 清空所有断开连接的监听
  void clearDisconnectedListener() {
    _disconnectedListeners.clear();
  }

  /// 添加连接错误的监听
  void addConnectErrorListener(
      void Function(dynamic target, Object error) listener) {
    if (!_connectErrorListeners.contains(listener)) {
      _connectErrorListeners.add(listener);
    }
  }

  /// 移除连接错误的监听
  void removeConnectErrorListener(
      void Function(dynamic target, Object error) listener) {
    if (_connectErrorListeners.contains(listener)) {
      _connectErrorListeners.remove(listener);
    }
  }

  /// 清空所有连接错误的监听
  void clearConnectErrorListener() {
    _connectErrorListeners.clear();
  }

  /// 连接
  void connect({int timeoutMilliseconds = 2000}) {
    _device.connect(timeoutMilliseconds: timeoutMilliseconds);
  }

  /// 连接
  void connectToAdvertisingDevice(Uuid serviceId,
      {int timeoutMilliseconds = 2000}) {
    _device.connectToAdvertisingDevice(serviceId,
        timeoutMilliseconds: timeoutMilliseconds);
  }

  /// 断开连接
  Future<void> disconnect() async {
    await _cancelNotifies();
    await _device.disconnect();
  }

  /// 向一个 characteristic 写入数据数据
  Future<void> writeCharacteristicWithResponse(
      Uuid serviceId, Uuid characteristicId, Uint8List data) async {
    await _device.writeCharacteristicWithResponse(
        serviceId, characteristicId, data);
  }

  /// 向一个 characteristic 写入无应答数据数据
  Future<void> writeCharacteristicWithoutResponse(
      Uuid serviceId, Uuid characteristicId, Uint8List data) async {
    await _device.writeCharacteristicWithoutResponse(
        serviceId, characteristicId, data);
  }

  /// 从指定的 characteristic 读取数据
  Future<Uint8List> readCharacteristic(
      Uuid serviceId, Uuid characteristicId) async {
    return await _device.readCharacteristic(serviceId, characteristicId);
  }

  /// 请求修改mtu
  Future<int> requestMtu(int mtu, {int timeout = 2000}) async {
    return await _device.requestMtu(mtu, timeout: timeout);
  }

  /// 请求建议的MTU大小
  Future<int> requestSuggestedMtu() {
    return _mtuHelper.requestSuggestedMtu();
  }

  Map<String, _NotifyData> notifyMap = {};

  /// 添加通知监听
  void addNotifyListener(Uuid serviceId, Uuid characteristicId,
      void Function(dynamic target, Uint8List data) listener) {
    String key = serviceId.toString().toLowerCase() +
        "-" +
        characteristicId.toString().toLowerCase();

    late _NotifyData notifyData;
    if (notifyMap.containsKey(key)) {
      notifyData = notifyMap[key]!;
    } else {
      notifyData = _NotifyData(serviceId, characteristicId);
      notifyMap[key] = notifyData;
    }
    notifyData.addListener(listener);

    //如果已经建立连接了则直接建立订阅
    if (_device.connected) {
      //没注册过就注册进去一个
      if (notifyData.streamSubscription == null) {
        StreamSubscription<Uint8List> stream = _device
            .subscribeToCharacteristic(serviceId, characteristicId)
            .listen((data) {
          notifyData.callAll(_target, data);
        });
        notifyData.streamSubscription = stream;
      }
    }
  }

  /// 移除通知监听
  Future<void> removeNotifyListener(Uuid serviceId, Uuid characteristicId,
      void Function(dynamic target, Uint8List data) listener) async {
    String key = serviceId.toString().toLowerCase() +
        "-" +
        characteristicId.toString().toLowerCase();

    _NotifyData? notifyData;
    if (notifyMap.containsKey(key)) {
      notifyData = notifyMap[key]!;
    }
    if (notifyData == null) {
      return;
    }
    notifyData.removeListener(listener);
    //如果已经没有监听了，则清空之前的订阅
    if (notifyData.listenerLength == 0) {
      notifyMap.remove(key);
      await notifyData.streamSubscription?.cancel();
      if (Platform.isIOS) {
        //TODO IOS底层应该是有bug，cancel的停止没有等到，所以这里手动延时下，看之后如何从底层修改掉这个问题。
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  /// 确保已连接
  Future<void> ensureConnected() async {
    Completer<void> completer = Completer();
    if (connected) {
      completer.complete();
    } else {
      if (disconnected || disposed) {
        completer.completeError("Peripheral has been disconnected of disposed");
      } else {
        void Function()? clear;
        void connectedHandler(peripheral) {
          if (clear != null) {
            clear();
          }
          completer.complete();
        }

        void disconnectedHandler(peripheral) {
          if (clear != null) {
            clear();
          }
          completer.completeError("connect fail");
        }

        void connectedErrorHandler(peripheral, error) {
          if (clear != null) {
            clear();
          }
          completer.completeError("connect error");
        }

        clear = () {
          removeConnectedListener(connectedHandler);
          removeDisconnectedListener(disconnectedHandler);
          removeConnectErrorListener(connectedErrorHandler);
        };
        addConnectedListener(connectedHandler);
        addDisconnectedListener(disconnectedHandler);
        addConnectErrorListener(connectedErrorHandler);
        if (!connecting) {
          connect();
        }
      }
    }
    return completer.future;
  }

  /// 写数据，可以忽视mtu限制
  /// 前提是已经调用了 initRequestSuggestMtu 初始化了最佳mtu
  Future<void> writeBytes(
      Uuid serviceId, Uuid characteristicId, Uint8List bytes) async {
    if (disconnected || disposed) {
      throw Exception("Can not call this after disposed or disconnected");
    }
    return _writeBytesHelper.writeBytes(serviceId, characteristicId, bytes);
  }

  /// 添加一个长数据的监听
  void addBytesListener(Uuid serviceId, Uuid characteristicId,
      void Function(dynamic target, Uint8List data) listener) {
    if (disconnected || disposed) {
      throw Exception("Can not call this after disposed or disconnected");
    }
    _receiveBytesHelper.addBytesListener(
        serviceId, characteristicId, listener, _target);
  }

  /// 移除一个长数据的监听
  Future<void> removeBytesListener(Uuid serviceId, Uuid characteristicId,
      void Function(dynamic target, Uint8List data) listener) async {
    if (disconnected || disposed) {
      throw Exception("Can not call this after disposed or disconnected");
    }
    await _receiveBytesHelper.removeBytesListener(
        serviceId, characteristicId, listener);
  }

  /// 请求一个数据，收到mtu的限制
  Future<Uint8List> request(
      Uuid serviceId, Uuid characteristicId, Uint8List data) async {
    if (disconnected || disposed) {
      throw Exception("Can not call this after disposed or disconnected");
    }
    await ensureConnected();
    return _RequesHelper(serviceId, characteristicId, this).request(data);
  }

  /// 请求一个数据，不受到mtu的限制
  Future<Uint8List> requestBytes(
      Uuid serviceId, Uuid characteristicId, Uint8List data) async {
    if (disconnected || disposed) {
      throw Exception("Can not call this after disposed or disconnected");
    }
    await ensureConnected();
    return _requestBytesHelper.request(serviceId, characteristicId, data);
  }

  /// 释放
  Future<void> dispose() async {
    _connectedListeners.clear();
    _disconnectedListeners.clear();
    _connectErrorListeners.clear();
    await _disposeNotifies();
    await _device.dispose();
  }
}

/// 设置了服务的从设备
class BlePeripheralService extends Object {
  late final BlePeripheral _device;
  late final Uuid _serviceId;

  /// 可发送的包的大小
  int get packageSize => _device.packageSize;

  BlePeripheralService._(
      String deviceId, Uuid serviceId, FlutterReactiveBle flutterReactiveBle) {
    _device = BlePeripheral._(deviceId, flutterReactiveBle, this);
    _serviceId = serviceId;
  }

  ///当前是否是已连接状态
  bool get connected => _device.connected;

  ///是否已释放
  bool get disposed => _device.disposed;

  /// 是否已经断开连接
  bool get disconnected => _device.disconnected;

  /// 是否在连接中
  bool get connecting => _device.connecting;

  /// 添加已连接的监听
  void addConnectedListener(void Function(dynamic target) listener) {
    _device.addConnectedListener(listener);
  }

  /// 移除已连接的监听
  void removeConnectedListener(void Function(dynamic target) listener) {
    _device.removeConnectedListener(listener);
  }

  /// 清空所有已连接监听
  void clearConnectedListener() {
    _device.clearConnectedListener();
  }

  /// 添加断开连接的监听
  void addDisconnectedListener(void Function(dynamic target) listener) {
    _device.addDisconnectedListener(listener);
  }

  /// 移除断开连接的监听
  void removeDisconnectedListener(void Function(dynamic target) listener) {
    _device.removeDisconnectedListener(listener);
  }

  /// 清空所有断开连接的监听
  void clearDisconnectedListener() {
    _device.clearDisconnectedListener();
  }

  /// 添加连接错误的监听
  void addConnectErrorListener(
      void Function(dynamic target, Object error) listener) {
    _device.addConnectErrorListener(listener);
  }

  /// 移除连接错误的监听
  void removeConnectErrorListener(
      void Function(dynamic target, Object error) listener) {
    _device.removeConnectErrorListener(listener);
  }

  /// 清空所有连接错误的监听
  void clearConnectErrorListener() {
    _device.clearConnectErrorListener();
  }

  /// 确保已连接
  Future<void> ensureConnected() async {
    await _device.ensureConnected();
  }

  /// 连接
  void connect({int timeoutMilliseconds = 2000}) {
    _device.connect(timeoutMilliseconds: timeoutMilliseconds);
  }

  /// 连接
  void connectToAdvertisingDevice(Uuid serviceId,
      {int timeoutMilliseconds = 2000}) {
    _device.connectToAdvertisingDevice(serviceId,
        timeoutMilliseconds: timeoutMilliseconds);
  }

  /// 断开连接
  Future<void> disconnect() async {
    await _device.disconnect();
  }

  /// 向一个 characteristic 写入数据数据
  Future<void> writeCharacteristicWithResponse(
      Uuid characteristicId, Uint8List data) async {
    await _device.writeCharacteristicWithResponse(
        _serviceId, characteristicId, data);
  }

  /// 向一个 characteristic 写入无应答数据数据
  Future<void> writeCharacteristicWithoutResponse(
      Uuid characteristicId, Uint8List data) async {
    await _device.writeCharacteristicWithoutResponse(
        _serviceId, characteristicId, data);
  }

  /// 从指定的 characteristic 读取数据
  Future<Uint8List> readCharacteristic(Uuid characteristicId) async {
    return await _device.readCharacteristic(_serviceId, characteristicId);
  }

  /// 请求修改mtu
  Future<int> requestMtu(int mtu, {int timeout = 2000}) async {
    return await _device.requestMtu(mtu, timeout: timeout);
  }

  /// 初始化请求建议的MTU大小
  Future<int> requestSuggestedMtu() {
    return _device.requestSuggestedMtu();
  }

  /// 请求一个数据，收到mtu的限制
  Future<Uint8List> request(Uuid characteristicId, Uint8List data) async {
    if (disconnected || disposed) {
      throw Exception("Can not call this after disposed or disconnected");
    }
    await ensureConnected();
    return _device.request(_serviceId, characteristicId, data);
  }

  /// 请求一个数据，不受到mtu的限制
  Future<Uint8List> requestBytes(Uuid characteristicId, Uint8List data) async {
    if (disconnected || disposed) {
      throw Exception("Can not call this after disposed or disconnected");
    }
    await ensureConnected();
    return _device.requestBytes(_serviceId, characteristicId, data);
  }

  /// 无回复的写数据，可以忽视mtu限制
  /// 前提是已经调用了 initRequestSuggestMtu 初始化了最佳mtu
  Future<void> writeBytes(Uuid characteristicId, Uint8List bytes) async {
    return _device.writeBytes(_serviceId, characteristicId, bytes);
  }

  /// 添加通知监听
  void addNotifyListener(Uuid characteristicId,
      void Function(dynamic target, Uint8List data) listener) {
    _device.addNotifyListener(_serviceId, characteristicId, listener);
  }

  /// 移除通知监听
  Future<void> removeNotifyListener(Uuid characteristicId,
      void Function(dynamic target, Uint8List data) listener) async {
    _device.removeNotifyListener(_serviceId, characteristicId, listener);
  }

  /// 添加一个长数据的监听
  void addBytesListener(Uuid characteristicId,
      void Function(dynamic target, Uint8List data) listener) {
    _device.addBytesListener(_serviceId, characteristicId, listener);
  }

  /// 移除一个长数据的监听
  Future<void> removeBytesListener(Uuid characteristicId,
      void Function(dynamic target, Uint8List data) listener) async {
    await _device.removeBytesListener(_serviceId, characteristicId, listener);
  }

  /// 释放
  Future<void> dispose() async {
    await _device.dispose();
  }
}
