part of ble_ex;

/// 通知数据
class _NotifyData {
  final List<NotifyListener> _listeners = [];
  final Uuid _service;
  Uuid get service => _service;
  final Uuid _characteristic;
  Uuid get characteristic => _characteristic;
  _NotifyData(this._service, this._characteristic);

  StreamSubscription<Uint8List>? streamSubscription;

  /// 添加一个监听器
  addListener(NotifyListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  /// 移除一个监听器
  removeListener(NotifyListener listener) {
    if (_listeners.contains(listener)) {
      _listeners.remove(listener);
    }
  }

  get listenerLength => _listeners.length;

  /// 调用所有监听器
  callAll(BlePeripheral target, Uint8List data) {
    List<NotifyListener> curListeners = [];
    for (var listener in _listeners) {
      curListeners.add(listener);
    }
    for (var listener in curListeners) {
      listener(target, service, characteristic, data);
    }
  }

  /// 清空所有监听器
  clear() {
    _listeners.clear();
  }
}
