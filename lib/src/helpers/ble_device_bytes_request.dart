part of ble_ex;

/// 单次有应答的请求
class _RequestBytesSingle {
  static int errorTypeTimeout = 1;
  static int errorTypeError = 2;
  static int timeout = 5000;

  BlePeripheral? _blePeripheral;
  Uuid? _serviceId;
  Uuid? _characteristicId;
  int _requestIndex = 0;
  _RequestBytesSingle(
      this._blePeripheral, this._serviceId, this._characteristicId) {
    _requestIndex = _getIndex("bytesRequest");
    _blePeripheral!
        .addBytesListener(_serviceId!, _characteristicId!, _bytesHandler);
  }

  bool callbacked = false;
  Timer? timeoutTimer;
  void Function(Uint8List)? _onComplete;
  void Function(int)? _onError;
  request(Uint8List request, void Function(Uint8List) onComplete,
      void Function(int) onError) async {
    _onComplete = onComplete;
    _onError = onError;
    List<int> finalList = [88, 99, _requestIndex, ...request.toList()];
    Uint8List finalData = Uint8List.fromList(finalList);

    try {
      await _blePeripheral!
          .writeBytes(_serviceId!, _characteristicId!, finalData);
    } catch (e) {
      clear();
      if (!callbacked && _onError != null) {
        callbacked = true;
        _onError!(errorTypeError);
      }
      clearFuncs();
    }
    timeoutTimer =
        Timer.periodic(Duration(milliseconds: timeout), (timer) async {
      await clear();
      if (!callbacked && _onError != null) {
        callbacked = true;
        _onError!(errorTypeTimeout);
      }
      clearFuncs();
    });
  }

  Future<void> _bytesHandler(dynamic target, Uint8List data) async {
    List<int> response = data.toList();
    if (response.length < 3) {
      return;
    }
    //验证头
    if (response[0] != 99 || response[1] != 88) {
      return;
    }
    //验证请求号
    int curRequestIndex = response[2];
    if (curRequestIndex != _requestIndex) {
      return;
    }
    await clear();
    Uint8List responseData = Uint8List.fromList(response.sublist(3));
    if (!callbacked && _onComplete != null) {
      callbacked = true;
      _onComplete!(responseData);
    }
    clearFuncs();
  }

  Future<void> clear() async {
    timeoutTimer?.cancel();
    timeoutTimer = null;
    await _blePeripheral?.removeBytesListener(
        _serviceId!, _characteristicId!, _bytesHandler);
  }

  void clearFuncs() {
    _blePeripheral = null;
    _serviceId = null;
    _characteristicId = null;
    _onComplete = null;
    _onError = null;
  }
}

/// 有应答的请求
class _RequestBytesHelper {
  static const int retryTimes = 2;

  final BlePeripheral _blePeripheral;
  _RequestBytesHelper(this._blePeripheral) {
    _blePeripheral.addDisconnectedListener(_disconnectHandler);
    _blePeripheral.addConnectErrorListener(_connectErrorHandler);
  }

  Future<Uint8List> request(
      Uuid serviceId, Uuid characteristicId, Uint8List request) {
    Completer<Uint8List> complete = Completer();
    _doRequest(serviceId, characteristicId, request, complete, 0);
    return complete.future;
  }

  _RequestBytesSingle? _singleReqeust;
  void _doRequest(Uuid serviceId, Uuid characteristicId, Uint8List request,
      Completer<Uint8List> complete, int curRetryTimes) {
    _singleReqeust =
        _RequestBytesSingle(_blePeripheral, serviceId, characteristicId);
    _singleReqeust!.request(request, (data) async {
      await clear();
      complete.complete(data);
    }, (error) async {
      if (curRetryTimes < retryTimes) {
        curRetryTimes += 1;
        _doRequest(
            serviceId, characteristicId, request, complete, curRetryTimes);
      } else {
        await clear();
        if (error == _RequestBytesSingle.errorTypeError) {
          complete.completeError("error");
        } else if (error == _RequestBytesSingle.errorTypeTimeout) {
          complete.completeError("time out");
        }
      }
    });
  }

  void _disconnectHandler(dynamic target) {
    clear();
  }

  void _connectErrorHandler(dynamic target, e) {
    clear();
  }

  Future<void> clear() async {
    await _singleReqeust?.clear();
    _singleReqeust?.clearFuncs();
  }
}
