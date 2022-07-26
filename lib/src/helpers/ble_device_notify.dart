part of ble_ex;

/// 通知数据
class _NotifyData {
  final List<void Function(dynamic target, Uint8List data)> _listeners = [];
  final Uuid _serviceId;
  Uuid get serviceId => _serviceId;
  final Uuid _characteristicId;
  Uuid get characteristicId => _characteristicId;
  _NotifyData(this._serviceId, this._characteristicId);

  StreamSubscription<Uint8List>? streamSubscription;

  /// 添加一个监听器
  addListener(void Function(dynamic target, Uint8List data) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  /// 移除一个监听器
  removeListener(void Function(dynamic target, Uint8List data) listener) {
    if (_listeners.contains(listener)) {
      _listeners.remove(listener);
    }
  }

  get listenerLength => _listeners.length;

  /// 调用所有监听器
  callAll(dynamic target, Uint8List data) {
    List<void Function(dynamic target, Uint8List data)> curListeners = [];
    for (var listener in _listeners) {
      curListeners.add(listener);
    }
    for (var listener in curListeners) {
      listener(target, data);
    }
  }

  /// 清空所有监听器
  clear() {
    _listeners.clear();
  }
}
