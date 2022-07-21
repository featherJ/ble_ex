part of ble_ex;

/// 单次有应答的请求
class _RequesHelperSingle {
  final Uuid _requestCharacteristic;
  final Uuid _requestServiceId;
  BlePeripheral? _blePeripheral;
  int _requestIndex = 0;
  _RequesHelperSingle(this._requestServiceId, this._requestCharacteristic,
      this._blePeripheral) {
    _requestIndex = _getIndex('reqeust');
    _blePeripheral!.addDisconnectedListener(_disconnectHandler);
    _blePeripheral!.addConnectErrorListener(_connectErrorHandler);
  }

  Timer? timer;
  bool callbacked = false;
  void Function(Uint8List)? _onComplete;
  void Function(Object)? _onError;
  request(Uint8List data, void Function(Uint8List) onComplete,
      void Function(Object) onError) async {
    _onComplete = onComplete;
    _onError = onError;

    _blePeripheral!.addNotifyListener(
        _requestServiceId, _requestCharacteristic, _requestNotifyHandler);
    timer = Timer.periodic(const Duration(milliseconds: 5000), (timer) async {
      await clear(fire: false);
      if (!callbacked) {
        callbacked = true;
        _onError!("Request Timeout");
      }
    });
    List<int> finalList = [_requestIndex, ...data.toList()];
    Uint8List finalData = Uint8List.fromList(finalList);
    try {
      await _blePeripheral!.writeCharacteristicWithoutResponse(
          _requestServiceId, _requestCharacteristic, finalData);
    } catch (e) {
      clear(fire: false);
      if (!callbacked) {
        callbacked = true;
        _onError!(e);
      }
    }
  }

  Future<void> _requestNotifyHandler(dynamic target, Uint8List data) async {
    List<int> response = data.toList();
    if (response.isEmpty) {
      return;
    }
    int curRequestIndex = response[0];
    if (curRequestIndex != _requestIndex) {
      return;
    }
    await clear(fire: false);
    response.removeAt(0);
    Uint8List responseData = Uint8List.fromList(response);
    if (!callbacked) {
      callbacked = true;
      _onComplete!(responseData);
    }
  }

  void _disconnectHandler(dynamic target) async {
    if (!callbacked) {
      callbacked = true;
      _onError!("disconnected");
    }
    await clear(fire: false);
  }

  void _connectErrorHandler(dynamic target, e) async {
    if (!callbacked) {
      callbacked = true;
      _onError!("connection error:" + e.toString());
    }
    await clear(fire: false);
  }

  Future<void> clear({bool fire = true}) async {
    timer?.cancel();
    await _blePeripheral?.removeNotifyListener(
        _requestServiceId, _requestCharacteristic, _requestNotifyHandler);
    _blePeripheral?.removeDisconnectedListener(_disconnectHandler);
    _blePeripheral?.removeConnectErrorListener(_connectErrorHandler);
    _blePeripheral = null;
    if (fire) {
      if (!callbacked) {
        callbacked = true;
        _onError!("request cancel");
      }
    }
  }
}

/// 有应答的请求
class _RequesHelper {
  //重试次数
  static const int _retryTimes = 2;
  final Uuid _requestCharacteristic;
  final Uuid _requestServiceId;
  BlePeripheral? _blePeripheral;

  _RequesHelper(this._requestServiceId, this._requestCharacteristic,
      this._blePeripheral) {
    _blePeripheral!.addDisconnectedListener(_disconnectHandler);
    _blePeripheral!.addConnectErrorListener(_connectErrorHandler);
  }

  final Completer<Uint8List> _complete = Completer();
  Future<Uint8List> request(Uint8List data) async {
    _doRequest(data, 0);
    return _complete.future;
  }

  _RequesHelperSingle? _singleReqeust;
  _doRequest(Uint8List data, retryTimes) {
    _singleReqeust = _RequesHelperSingle(
        _requestServiceId, _requestCharacteristic, _blePeripheral!);
    _singleReqeust!.request(data, (result) {
      clear();
      _complete.complete(result);
    }, (error) {
      if (_disposed) {
        clear();
        _complete.completeError(error);
      } else if (retryTimes < _retryTimes) {
        //重试
        _doRequest(data, retryTimes + 1);
      } else {
        clear();
        _complete.completeError(error);
      }
    });
  }

  void _disconnectHandler(dynamic target) {
    _singleReqeust?._disconnectHandler(target);
    clear();
  }

  void _connectErrorHandler(dynamic target, e) {
    _singleReqeust?._connectErrorHandler(target, e);
    clear();
  }

  bool _disposed = false;
  void clear() {
    _disposed = true;
    _singleReqeust?.clear();
    _blePeripheral?.removeDisconnectedListener(_disconnectHandler);
    _blePeripheral?.removeConnectErrorListener(_connectErrorHandler);
    _blePeripheral = null;
  }
}
