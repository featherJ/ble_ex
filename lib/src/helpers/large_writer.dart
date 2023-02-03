part of ble_ex;

/// 长数据发送器
class _LargerWriter {
  static const String _tag = "LargeWriter";
  final BlePeripheral _blePeripheral;
  _LargerWriter(this._blePeripheral);

  Future<void> write(Uuid service, Uuid characteristic, Uint8List bytes) async {
    bleLog(_tag,
        "Writing bytes(length:${bytes.length}) to {service:${service.toString()}, characteristic:${characteristic.toString()}}.");

    var requestIndex = _getIndex("write");
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
        package.add(_DataTags.msWriteLarge[0]);
        package.add(_DataTags.msWriteLarge[1]);
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

    while (packages.isNotEmpty) {
      var package = packages.removeAt(0);
      await _blePeripheral.writeWithResponse(
          service, characteristic, Uint8List.fromList(package));
    }
  }
}
