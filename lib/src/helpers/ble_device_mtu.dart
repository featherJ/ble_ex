part of ble_ex;

/// Mtu申请
class _MtuHelper {
  static const List<int> muts = [103, 241, 512];
  static const int minMtu = 23;

  int _suggestedMtu = -1;

  /// 得到建议的mtu，-1表示为初始化
  int get suggestedMtu => _suggestedMtu;

  final BlePeripheral _blePeripheral;

  int _packageSize = 20;

  /// 可发送的包的大小
  int get packageSize => _packageSize;

  _MtuHelper(this._blePeripheral);

  Future<int>? finalFuture;

  /// 初始化请求建议的MTU大小
  Future<int> requestSuggestedMtu() async {
    //确保不会被重复请求
    if (finalFuture != null) {
      return finalFuture!;
    }
    _blePeripheral.fireConnectEvent = false;
    Completer<int> completer = Completer();
    _doRequestSuggestedMtu((mtu) {
      if (Platform.isIOS) {
        _packageSize = mtu;
      } else if (Platform.isAndroid) {
        _packageSize = mtu - 3;
      } else {
        _packageSize = mtu;
      }
      _blePeripheral.fireConnectEvent = true;
      completer.complete(mtu);
    });
    finalFuture = completer.future;
    return finalFuture!;
  }

  int? cacheMaxMtu;
  bool mtuReRequested = false;
  void _doRequestSuggestedMtu(void Function(int) complete) async {
    try {
      int mtuResult = await _doRequestSuggestedMtuSingle(mtu: cacheMaxMtu);
      complete(mtuResult);
    } catch (e) {
      //错误只能是超时，android的如果协商一个mtu不成功的话是30内没有回应的，因为android的ble超时时间是30秒
      //该问题只在部分android设备中出现，另外有的设备会直接返回可行的值
      //在这段时间里是阻塞状态，无法发送任何消息，所以只能关闭连接重新建立连接
      cacheMaxMtu = e as int;
      void Function()? onConnected;
      onConnected = () {
        _blePeripheral._innerConnectedFuncs.remove(onConnected);
        if (!mtuReRequested) {
          _doRequestSuggestedMtu(complete);
        } else {
          complete(minMtu);
        }
        mtuReRequested = true;
      };
      _blePeripheral._innerConnectedFuncs.add(onConnected);
      await _blePeripheral.disconnect();
      _blePeripheral.connect();
    }
  }

  /// 初始化请求建议的MTU大小
  Future<int> _doRequestSuggestedMtuSingle({int? mtu}) async {
    if (_blePeripheral.disposed || _blePeripheral.disconnected) {
      throw Exception("Can not call this after disposed or disconnected");
    }
    var mtuResult = minMtu;
    _suggestedMtu = mtuResult;
    Completer<int> completer = Completer();
    if (mtu != null) {
      try {
        mtuResult = await _blePeripheral.requestMtu(mtu);
        _suggestedMtu = mtuResult;
        completer.complete(_suggestedMtu);
      } catch (e) {
        if (e == 408) {
          completer.completeError(_suggestedMtu);
        } else {
          completer.complete(_suggestedMtu);
        }
      }
    } else {
      var hasError = false;
      for (var i = 0; i < muts.length; i++) {
        int time = DateTime.now().millisecondsSinceEpoch;
        bleLog(BlePeripheral._tag, 'Requesting mtu:${muts[i]}');
        try {
          mtuResult = await _blePeripheral.requestMtu(muts[i], timeout: 2000);
          int current = DateTime.now().millisecondsSinceEpoch;
          bleLog(BlePeripheral._tag,
              'Mtu:${muts[i]} responded, cost:${(current - time).toString()} value:${mtuResult.toString()}');
          _suggestedMtu = mtuResult;
        } catch (e) {
          hasError = true;
          int current = DateTime.now().millisecondsSinceEpoch;
          bleLog(BlePeripheral._tag,
              'Request mtu:${muts[i]} error, cost:${(current - time).toString()} error:${e.toString()}');
          if (e == 408) {
            completer.completeError(_suggestedMtu);
          } else {
            completer.complete(_suggestedMtu);
          }
          break;
        }
      }
      if (!hasError) {
        completer.complete(_suggestedMtu);
      }
    }
    return completer.future;
  }
}
