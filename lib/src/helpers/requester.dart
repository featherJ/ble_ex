part of ble_ex;

class _SingleRequester {
  final Uuid _requestCharacteristic;
  final Uuid _requestService;
  BlePeripheral? _blePeripheral;
  int _requestIndex = 0;
  _SingleRequester(
      this._requestService, this._requestCharacteristic, this._blePeripheral) {
    _requestIndex = _getIndex('reqeust');
    _blePeripheral!.addDisconnectedListener(_disconnectHandler);
    _blePeripheral!.addConnectErrorListener(_connectErrorHandler);
  }

  bool callbacked = false;
  void Function(Uint8List)? _onComplete;
  void Function(Object)? _onError;
  request(Uint8List data, void Function(Uint8List) onComplete,
      void Function(Object) onError) async {
    _onComplete = onComplete;
    _onError = onError;
    _blePeripheral!.addNotifyListener(
        _requestService, _requestCharacteristic, _notifyHandler);
    List<int> finalList = [_requestIndex, ...data.toList()];
    Uint8List finalData = Uint8List.fromList(finalList);
    try {
      await _blePeripheral!.writeWithResponse(
          _requestService, _requestCharacteristic, finalData);
    } catch (e) {
      clear();
      if (!callbacked) {
        callbacked = true;
        _onError!(e);
      }
    }
  }

  Future<void> _notifyHandler(
      BlePeripheral target, Uuid s, Uuid c, Uint8List data) async {
    List<int> response = data.toList();
    if (response.isEmpty) {
      return;
    }
    int curRequestIndex = response[0];
    if (curRequestIndex != _requestIndex) {
      return;
    }
    await clear();
    response.removeAt(0);
    Uint8List responseData = Uint8List.fromList(response);
    if (!callbacked) {
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
    await _blePeripheral?.removeNotifyListener(
        _requestService, _requestCharacteristic, _notifyHandler);
    _blePeripheral?.removeDisconnectedListener(_disconnectHandler);
    _blePeripheral?.removeConnectErrorListener(_connectErrorHandler);
    _blePeripheral = null;
  }
}

class _Requester {
  final BlePeripheral _blePeripheral;
  _Requester(this._blePeripheral);
  Future<Uint8List> request(
      Uuid service, Uuid characteristic, Uint8List request) {
    Completer<Uint8List> completer = Completer();

    _SingleRequester requester =
        _SingleRequester(service, characteristic, _blePeripheral);
    requester.request(request, (result) {
      completer.complete(result);
    }, (error) {
      completer.completeError(error);
    });
    return completer.future;
  }
}
