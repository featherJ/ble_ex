part of ble_ex;

/// 从设备
class BlePeripheral extends Object {
  static const String _tag = "BlePeripheral";

  late _SuggestMtuRequester _suggestMtuRequester;

  /// 得到建议的mtu，-1表示为初始化
  int get suggestedMTU => _suggestMtuRequester.suggestedMtu;

  /// 可发送的包的大小
  int get packageSize => _suggestMtuRequester.packageSize;

  late _BlePeripheralCore _device;

  bool fireConnectEvent = true;
  late BlePeripheral _self;
  BlePeripheral._(String deviceId, FlutterReactiveBle flutterReactiveBle) {
    _self = this;

    _suggestMtuRequester = _SuggestMtuRequester(this);
    // _requesHelper = _RequesHelper(this);
    // _writeBytesHelper = _WriteBytesHelper(this);
    // _receiveBytesHelper = _ReceiveBytesHelper(this);
    // _requestBytesHelper = _RequestBytesHelper(this);
    _device = _BlePeripheralCore._(deviceId, flutterReactiveBle);
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
          List<void Function(BlePeripheral)> curConnectedListeners = [];
          for (var listener in _connectedListeners) {
            curConnectedListeners.add(listener);
          }
          for (var listener in curConnectedListeners) {
            listener(_self);
          }
        }
      }
      if (event.connectionState == DeviceConnectionState.disconnected) {
        bleLog(_tag, "Inner disconnected");
        _cancelNotifies();
        if (fireConnectEvent) {
          List<void Function(BlePeripheral)> curDisconnectedListeners = [];
          for (var listener in _disconnectedListeners) {
            curDisconnectedListeners.add(listener);
          }
          for (var listener in curDisconnectedListeners) {
            listener(_self);
          }
        }
      }
    }, onError: (error) {
      bleLog(_tag, 'Inner error:${error.toString()}');
      List<void Function(BlePeripheral, Object)> curConnectErrorListeners = [];
      for (var listener in _connectErrorListeners) {
        curConnectErrorListeners.add(listener);
      }
      for (var listener in curConnectErrorListeners) {
        listener(_self, error);
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

  Map<String, _NotifyData> notifyMap = {};

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
          notifyData.callAll(_self, data);
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

  final List<void Function(BlePeripheral)> _connectedListeners = [];
  final List<void Function(BlePeripheral)> _disconnectedListeners = [];
  final List<void Function(BlePeripheral, Object)> _connectErrorListeners = [];

  /// 添加已连接的监听
  void addConnectedListener(void Function(BlePeripheral target) listener) {
    if (!_connectedListeners.contains(listener)) {
      _connectedListeners.add(listener);
    }
  }

  /// 移除已连接的监听
  void removeConnectedListener(void Function(BlePeripheral target) listener) {
    if (_connectedListeners.contains(listener)) {
      _connectedListeners.remove(listener);
    }
  }

  /// 清空所有已连接监听
  void clearConnectedListener() {
    _connectedListeners.clear();
  }

  /// 添加断开连接的监听
  void addDisconnectedListener(void Function(BlePeripheral target) listener) {
    if (!_disconnectedListeners.contains(listener)) {
      _disconnectedListeners.add(listener);
    }
  }

  /// 移除断开连接的监听
  void removeDisconnectedListener(
      void Function(BlePeripheral target) listener) {
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
      void Function(BlePeripheral target, Object error) listener) {
    if (!_connectErrorListeners.contains(listener)) {
      _connectErrorListeners.add(listener);
    }
  }

  /// 移除连接错误的监听
  void removeConnectErrorListener(
      void Function(BlePeripheral target, Object error) listener) {
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
  Future<void> writeWithResponse(
      Uuid serviceId, Uuid characteristicId, Uint8List data) async {
    await ensureConnected();
    await _device.writeCharacteristicWithResponse(
        serviceId, characteristicId, data);
  }

  /// 向一个 characteristic 写入无应答数据数据
  Future<void> writeWithoutResponse(
      Uuid serviceId, Uuid characteristicId, Uint8List data) async {
    await ensureConnected();
    await _device.writeCharacteristicWithoutResponse(
        serviceId, characteristicId, data);
  }

  /// 从指定的 characteristic 读取数据
  Future<Uint8List> read(Uuid serviceId, Uuid characteristicId) async {
    await ensureConnected();
    Uint8List result =
        await _device.readCharacteristic(serviceId, characteristicId);
    return result;
  }

  /// 请求修改mtu
  Future<int> requestMtu(int mtu, {int timeout = 2000}) async {
    await ensureConnected();
    int result = await _device.requestMtu(mtu, timeout: timeout);
    return result;
  }

  /// 请求优先级，仅在android上生效
  Future<void> requestConnectionPriority(ConnectionPriority priority) async {
    await ensureConnected();
    await _device.requestConnectionPriority(priority);
  }

  /// 请求建议的MTU大小
  Future<int> requestSuggestedMtu() async {
    await ensureConnected();
    int result = await _suggestMtuRequester.requestSuggestedMtu();
    return result;
  }

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
          notifyData.callAll(_self, data);
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

  Future<void>? ensureConnectedFuture;

  /// 确保已连接
  Future<void> ensureConnected() async {
    if (disconnected || disposed) {
      throw Exception("Peripheral has been disconnected of disposed");
    }
    if (connected) {
      return;
    }
    if (ensureConnectedFuture != null) {
      return ensureConnectedFuture;
    }
    Completer<void> completer = Completer();
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
    ensureConnectedFuture = completer.future;
    return ensureConnectedFuture!;
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
