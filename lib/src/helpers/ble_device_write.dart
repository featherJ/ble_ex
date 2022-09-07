part of ble_ex;

/// 长数据发射器
class _WriteBytesHelper {
  static const String _tag = "_WriteBytesHelper";
  final BlePeripheral _blePeripheral;
  _WriteBytesHelper(this._blePeripheral);

  /// 有回馈的写数据，可以忽视mtu限制
  /// 前提是已经调用了 initRequestSuggestMtu 初始化了最佳mtu
  Future<void> writeBytes(
      Uuid serviceId, Uuid characteristicId, Uint8List bytes) async {
    bleLog(_tag,
        "Writing bytes(length:${bytes.length}) to {service:${serviceId.toString()}, characteristic:${characteristicId.toString()}}.");
    await _blePeripheral._ensureSafe(false);
    Completer completer = Completer();
    bool completed = false;
    var requestIndex = _getIndex("write");
    Timer? timer;
    void Function(dynamic target, Uint8List data)? onResponse;
    clear() {
      timer?.cancel();
      if (onResponse != null) {
        _blePeripheral.removeNotifyListener(
            serviceId, characteristicId, onResponse);
      }
    }

    onResponse = (dynamic target, Uint8List data) {
      var datalist = data.toList();
      if (datalist.length >= 4 && datalist[0] == 120 && datalist[1] == 120) {
        var curRequestIndex = datalist[2];
        var result = datalist[3];
        if (curRequestIndex == requestIndex) {
          if (result == 0) {
            if (!completed) {
              completer.complete();
            }
            completed = true;
            clear();
          } else if (result == 1) {
            if (!completed) {
              completer.completeError('write bytes error');
            }
            completed = true;
            clear();
          } else if (result == 2) {
            if (!completed) {
              completer.completeError('write bytes timeout');
            }
            completed = true;
            clear();
          }
        }
      }
    };

    _blePeripheral.addNotifyListener(serviceId, characteristicId, onResponse);
    //首包：请求号+起始包标识+包数据长度+包个数+报数据
    //其他包：请求号+包索引+包数据

    var packageSize = _blePeripheral.packageSize;
    var datas = bytes.toList();
    int dataSize = bytes.length;
    ByteData dataSizeInt = ByteData(4);
    dataSizeInt.setInt32(0, dataSize);
    List<List<int>> packages = [];
    int start = 0;
    int index = 0;
    while (start <= dataSize) {
      List<int> package = [];
      int end = 0;
      //首包的处理
      if (start == 0) {
        //请求号
        package.add(requestIndex);
        //起始包标识
        package.add(120);
        package.add(110);
        //数据长度
        package.add(dataSizeInt.getInt8(0));
        package.add(dataSizeInt.getInt8(1));
        package.add(dataSizeInt.getInt8(2));
        package.add(dataSizeInt.getInt8(3));
        //包个数，先填写空白
        package.add(0);
        package.add(0);
        package.add(0);
        package.add(0);
        //包数据
        end = min(packageSize - 11, dataSize);
        List<int> data = datas.sublist(start, end);
        package.addAll(data);
        start = end;
      }
      //其他包的处理
      else {
        //请求号
        package.add(requestIndex);
        //包索引数
        ByteData indexInt = ByteData(4);
        indexInt.setInt32(0, index);
        package.add(indexInt.getInt8(0));
        package.add(indexInt.getInt8(1));
        package.add(indexInt.getInt8(2));
        package.add(indexInt.getInt8(3));
        //包数据
        end = min(start + packageSize - 5, dataSize);
        List<int> data = datas.sublist(start, end);
        package.addAll(data);
        start = end;
      }
      packages.add(package);
      index++;
      if (start == dataSize) {
        break;
      }
    }

    bleLog(_tag, "Split bytes to ${packages.length.toString()} packs.");

    //填补包个数
    ByteData packageNumInt = ByteData(4);
    packageNumInt.setInt32(0, packages.length);
    var firstPackage = packages[0];
    firstPackage[7] = packageNumInt.getInt8(0);
    firstPackage[8] = packageNumInt.getInt8(1);
    firstPackage[9] = packageNumInt.getInt8(2);
    firstPackage[10] = packageNumInt.getInt8(3);

    for (var package in packages) {
      if (completed) {
        break;
      }
      bleLog(_tag, "Writing one pack.");
      try {
        await _blePeripheral.writeCharacteristicWithoutResponse(
            serviceId, characteristicId, Uint8List.fromList(package));
      } catch (e) {
        bleLog(_tag, "Write one pack error.");
        if (!completed) {
          completer.completeError('write bytes error');
        }
        completed = true;
        clear();
        break;
      }
    }
    if (!completed) {
      timer = Timer.periodic(const Duration(milliseconds: 2000), (timer) async {
        timer.cancel();
        bleLog(_tag, "Write packs timeout.");
        if (!completed) {
          completer.completeError('write bytes timeout');
        }
        completed = true;
        clear();
      });
    }
    return completer.future;
  }
}
