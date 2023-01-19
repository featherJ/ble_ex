part of ble_ex;

/// 单个接收器
class _BytesRecevier {
  static const String _tag = "_BytesRecevier";

  //超时时间20秒，仅用于避免内存溢出
  static const int timeOut = 20000;

  final int _requestIndex;
  _BytesRecevier(this._requestIndex) {
    _initTimer();
  }

  void Function(int requestIndex, Uint8List data)? _onReceive;
  void Function(int requestIndex)? _onError;
  void Function(int requestIndex)? _onTimeout;
  void Function(int requestIndex)? _onFinish;

  /// 设置回调
  void setCallback(
    void Function(int requestIndex, Uint8List data) onReceive,
    void Function(int requestIndex) onError,
    void Function(int requestIndex) onTimeout,
    void Function(int requestIndex) onFinish,
  ) {
    _onReceive = onReceive;
    _onError = onError;
    _onTimeout = onTimeout;
    _onFinish = onFinish;
  }

  int _index = 0;
  int _packageSize = 0;
  int _packageNum = 0;
  final List<List<int>> _packages = [];
  void addPackage(Uint8List packData) {
    List<int> pack = packData.toList();
    if (_index == 0) {
      //是一个首包
      if (pack[1] == _DataTags.sm_indicate_large[0] &&
          pack[2] == _DataTags.sm_indicate_large[1]) {
        bleLog(_tag, "Received first pack");
        ByteData packageSizeData = ByteData(4);
        packageSizeData.setUint8(0, pack[3]);
        packageSizeData.setUint8(1, pack[4]);
        packageSizeData.setUint8(2, pack[5]);
        packageSizeData.setUint8(3, pack[6]);
        _packageSize = packageSizeData.getInt32(0);
        ByteData packageNumData = ByteData(4);
        packageNumData.setUint8(0, pack[7]);
        packageNumData.setUint8(1, pack[8]);
        packageNumData.setUint8(2, pack[9]);
        packageNumData.setUint8(3, pack[10]);
        _packageNum = packageNumData.getInt32(0);
        List<int> curPack = pack.sublist(11, pack.length);
        _packages.add(curPack);
      } else {
        bleLog(_tag, "Receiving first pack error");
        _cancelTimer();
        if (_onError != null && _onFinish != null) {
          _onError!(_requestIndex);
          _onFinish!(_requestIndex);
        }
        _clear();
      }
    } else {
      ByteData curIndexData = ByteData(4);
      curIndexData.setUint8(0, pack[1]);
      curIndexData.setUint8(1, pack[2]);
      curIndexData.setUint8(2, pack[3]);
      curIndexData.setUint8(3, pack[4]);
      int curIndex = curIndexData.getInt32(0);
      if (curIndex == _index) {
        List<int> curPack = pack.sublist(5, pack.length);
        _packages.add(curPack);
        bleLog(_tag, "Receivd rest pack");
      } else {
        _cancelTimer();
        bleLog(_tag, "Receiving rest pack error");
        if (_onError != null && _onFinish != null) {
          _onError!(_requestIndex);
          _onFinish!(_requestIndex);
        }
        _clear();
      }
    }
    _index++;
    if (_packageNum == _index) {
      List<int> finalBytes = [];
      for (int i = 0; i < _packages.length; i++) {
        finalBytes.addAll(_packages[i]);
      }
      if (finalBytes.length == _packageSize) {
        bleLog(_tag, "Received all packs");
        _cancelTimer();
        if (_onReceive != null && _onFinish != null) {
          _onReceive!(_requestIndex, Uint8List.fromList(finalBytes));
          _onFinish!(_requestIndex);
        }
        _clear();
      } else {
        _cancelTimer();
        bleLog(_tag, "Receiving all packs error");
        if (_onError != null && _onFinish != null) {
          _onError!(_requestIndex);
          _onFinish!(_requestIndex);
        }
        _clear();
      }
    }
    _updateTimer();
  }

  Timer? _timer;
  int _updateTimestamp = 0;
  void _initTimer() {
    _updateTimestamp = DateTime.now().millisecondsSinceEpoch;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      int nowTimestamp = DateTime.now().millisecondsSinceEpoch;
      if (nowTimestamp - _updateTimestamp >= timeOut) {
        _cancelTimer();
        bleLog(_tag, "Receiving packs timeout");
        if (_onTimeout != null && _onFinish != null) {
          _onTimeout!(_requestIndex);
          _onFinish!(_requestIndex);
        }
        _clear();
      }
    });
  }

  void _updateTimer() {
    _updateTimestamp = DateTime.now().millisecondsSinceEpoch;
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _clear() {
    _cancelTimer();
    _onReceive = null;
    _onError = null;
    _onTimeout = null;
    _onFinish = null;
  }
}

/// 指定特征的长数据接收器
class _ReceiveBytescharacteristic {
  static const String _tag = "ReceiveBytescharacteristic";

  final String _key;
  final BlePeripheral _blePeripheral;
  final Uuid _serviceId;
  final Uuid _characteristicId;
  final BlePeripheral _target;
  _ReceiveBytescharacteristic(this._key, this._blePeripheral, this._serviceId,
      this._characteristicId, this._target);

  String get key => _key;

  final List<NotifyListener> _listeners = [];
  bool _notifyListenerAdded = false;

  void addLargeIndicateListener(NotifyListener listener) {
    _listeners.add(listener);
    if (!_notifyListenerAdded) {
      _notifyListenerAdded = true;
      _blePeripheral.addNotifyListener(
          _serviceId, _characteristicId, notifyHandler);
    }
  }

  Future<void> removeLargeIndicateListener(NotifyListener listener) async {
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
      _notifyListenerAdded = false;
      await _blePeripheral.removeNotifyListener(
          _serviceId, _characteristicId, notifyHandler);
    }
  }

  final Map<int, _BytesRecevier> _bytesReceviers = {};
  void notifyHandler(BlePeripheral target, Uint8List pack) {
    int requestIndex = -1;
    if (pack.isNotEmpty) {
      requestIndex = pack[0];
    } else {
      return;
    }

    _BytesRecevier? receiver;
    if (_bytesReceviers.containsKey(requestIndex)) {
      receiver = _bytesReceviers[requestIndex];
    } else {
      //没有这个接收器，证明原则上应该是首包才对，如果不是首包还没找到接收器，则直接忽视这个包，应该是之前包的遗漏部分。
      if (pack.length >= 3 &&
          pack[1] == _DataTags.sm_indicate_large[0] &&
          pack[2] == _DataTags.sm_indicate_large[1]) {
        _BytesRecevier newReceiver = _BytesRecevier(requestIndex);
        newReceiver.setCallback((requestIndex, data) {
          bleLog(_tag,
              "Receive large bytes(length:${data.length.toString()}) complete with index:${requestIndex.toString()} from {service:${_serviceId.toString()}, characteristic:${_characteristicId.toString()}}.");
          _onReceiveBytes(data);
        }, (requestIndex) {
          bleLog(_tag,
              "Receive large bytes error with index:${requestIndex.toString()} from {service:${_serviceId.toString()}, characteristic:${_characteristicId.toString()}}.");
        }, (requestIndex) {
          bleLog(_tag,
              "Receive large bytes timeout with index:${requestIndex.toString()} from {service:${_serviceId.toString()}, characteristic:${_characteristicId.toString()}}.");
        }, (requestIndex) {
          _bytesReceviers.remove(requestIndex);
        });
        _bytesReceviers[requestIndex] = newReceiver;
        receiver = newReceiver;
      }
    }
    if (receiver != null) {
      receiver.addPackage(pack);
    }
  }

  void _onReceiveBytes(Uint8List data) {
    List<NotifyListener> curlisteners = [];
    for (var listener in _listeners) {
      curlisteners.add(listener);
    }
    for (var listener in curlisteners) {
      listener(_target, data);
    }
  }

  void clear() {
    _listeners.clear();
    _notifyListenerAdded = false;
    _blePeripheral.removeNotifyListener(
        _serviceId, _characteristicId, notifyHandler);
  }
}

/// 长数据指示接收器
class _LargeIndicateReceiver {
  final BlePeripheral _blePeripheral;
  _LargeIndicateReceiver(this._blePeripheral);

  Map<String, _ReceiveBytescharacteristic> receiveMap = {};

  /// 添加长数据监听
  void addLargeIndicateListener(Uuid serviceId, Uuid characteristicId,
      NotifyListener listener, BlePeripheral target) {
    var key = serviceId.toString() + "-" + characteristicId.toString();
    _ReceiveBytescharacteristic? receiver;
    if (receiveMap.containsKey(key)) {
      receiver = receiveMap[key];
    } else {
      receiver = _ReceiveBytescharacteristic(
          key, _blePeripheral, serviceId, characteristicId, target);
      receiveMap[key] = receiver;
    }
    receiver!.addLargeIndicateListener(listener);
  }

  /// 移除长数据监听
  Future<void> removeLargeIndicateListener(
      Uuid serviceId, Uuid characteristicId, NotifyListener listener) async {
    var key = serviceId.toString() + "-" + characteristicId.toString();
    if (receiveMap.containsKey(key)) {
      _ReceiveBytescharacteristic receiver = receiveMap[key]!;
      await receiver.removeLargeIndicateListener(listener);
    }
  }
}
