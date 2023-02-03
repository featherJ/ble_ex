part of ble_ex;

/// 单次有应答的请求
class _SingleLargeRequester {
  BlePeripheral? _blePeripheral;
  final Uuid? _service;
  final Uuid? _characteristic;
  int _requestIndex = 0;
  _SingleLargeRequester(
      this._service, this._characteristic, this._blePeripheral) {
    _requestIndex = _getIndex("largetRequest");
    _blePeripheral!.addDisconnectedListener(_disconnectHandler);
    _blePeripheral!.addConnectErrorListener(_connectErrorHandler);
  }

  bool callbacked = false;
  void Function(Uint8List)? _onComplete;
  void Function(Object)? _onError;
  late Uint8List finalData;
  request(Uint8List request, void Function(Uint8List) onComplete,
      void Function(Object) onError) async {
    _onComplete = onComplete;
    _onError = onError;
    _blePeripheral!.addLargeIndicateListener(
        _service!, _characteristic!, _largetIndicateHandler);
    List<int> finalList = [
      _DataTags.msRequestLarge[0],
      _DataTags.msRequestLarge[1],
      _requestIndex,
      ...request.toList()
    ];
    finalData = Uint8List.fromList(finalList);
    try {
      await _blePeripheral!.writeLarge(_service!, _characteristic!, finalData);
    } catch (e) {
      clear();
      if (!callbacked && _onError != null) {
        callbacked = true;
        _onError!(e);
      }
    }
  }

  Future<void> _largetIndicateHandler(
      BlePeripheral target, Uuid s, Uuid c, Uint8List data) async {
    List<int> response = data.toList();
    if (response.length < 3) {
      return;
    }
    //验证头
    if (response[0] != _DataTags.smResponseLarge[0] ||
        response[1] != _DataTags.smResponseLarge[1]) {
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
  }

  void _disconnectHandler(BlePeripheral target) async {
    if (!callbacked) {
      callbacked = true;
      _onError!("disconnected");
    }
    await clear();
  }

  void _connectErrorHandler(BlePeripheral target, e) async {
    if (!callbacked) {
      callbacked = true;
      _onError!("connection error:" + e.toString());
    }
    await clear();
  }

  Future<void> clear() async {
    await _blePeripheral?.removeLargeIndicateListener(
        _service!, _characteristic!, _largetIndicateHandler);
    _blePeripheral?.removeDisconnectedListener(_disconnectHandler);
    _blePeripheral?.removeConnectErrorListener(_connectErrorHandler);
    _blePeripheral = null;
  }
}

/// 长数据请求
class _LargeRequester {
  final BlePeripheral _blePeripheral;
  _LargeRequester(this._blePeripheral);
  Future<Uint8List> request(
      Uuid service, Uuid characteristic, Uint8List request) {
    Completer<Uint8List> completer = Completer();

    _SingleLargeRequester requester =
        _SingleLargeRequester(service, characteristic, _blePeripheral);
    requester.request(request, (result) {
      completer.complete(result);
    }, (error) {
      completer.completeError(error);
    });
    return completer.future;
  }
}
