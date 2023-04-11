# Flutter ble_ex library

[![pub](https://img.shields.io/pub/v/ble_ex?label=pub&color=success)](https://pub.dev/packages/ble_ex)

基于 [flutter_reactive_ble](https://github.com/PhilipsHue/flutter_reactive_ble) 实现的 BLE 中心设备的 Flutter 库，增加了更多中心设备与从设备的通信方式支持。

外围设备目前提供了如下版本的实现：

* [Android BleEx Library](https://github.com/featherJ/BleEx): 可以配合 Flutter 版本的 ble_ex 轻松实现 BLE 外围设备相关功能。
* iOS BleEx Library：还没开始搞..

## 安装

### 插件的安装
#### 从 pub.dev 安装
你可以通过命令 `flutter pub add ble_ex` 直接安装 `ble_ex` 插件，这将自动为你项目内的 `pubspec.yaml` 文件的 `dependencies` 字段中增加如下依赖
```yaml
dependencies:
  ble_ex: ^1.0.0
```
#### 从 github 安装
需要你手动在 `pubspec.yaml` 文件的 `dependencies` 字段中增加如下依赖
```yaml
dependencies:
  ble_ex:
    git:
      url: https://github.com/featherJ/ble_ex.git
      ref: ^0.9.9
```
然后执行命令
```
flutter pub get
```
进行该插件的安装。

### 项目的配置
由于该插件的实现依赖于 [flutter_reactive_ble](https://github.com/PhilipsHue/flutter_reactive_ble)，所以关于 Android 和 iOS 项目的配置需要参考 [flutter_reactive_ble](https://github.com/PhilipsHue/flutter_reactive_ble) 的文档进行。

## 功能简介
可以通过管理器创建一个外围设备的代理，之后不管是设备的连接还是通信，均通过该设备代理直接进行。能够让开发过程更加清晰，结构分明。

在使用原生 BLE 功能的时候，会在 Android 和 iOS 上遇到一些不一致的情况，该 ble_ex 中心设备库配合 Android 版的 BleEx 外围设备库为各种不一致现象做了处理，使得他们在同一套代码下表现效果一致。

同时针对部分原生 BLE 开发的坑，已在库内部做了处理，已达到尽可能的避免连接失败，或者连接卡死等情况出现。

### 功能
- 增加了连接时候的重试功能，会自动重试3次以增大连接成功的概率。
- 主设备可以通过一个方法直接申请最大的 `mtu` 值。*（在原生 `BLE` 中，部分 Android 机型申请指定 `mtu` 失败的时会直接导致阻塞卡死 30 秒的情况。在 `ble_ex` 库中已经为你绕过了这个问题，避免申请过程造成长时间阻塞的情况出现。）*
- 实现了带有数据请求方法，中心设备可以像外围设备的指定特征提交一段数据并请求一段数据。类似于 http 中的 `post` 方法。
- 实现了从中心设备到外围设备指定特征的长数据的发送，可以忽视 `mtu` 的限制，库内部自动完成了对于长数据的拆包与粘包过程。
- 实现了中心设备读取外围设备指定特征的长数据，同上可以忽视 `mtu` 的限制。
- 实现了监听并接收外围设备的指定特征的长数据的方法，同上可以忽视 `mtu` 的限制。
- 实现了带有长数据请求方法，类似于 http 中的 `post` 方法，同上可以忽视 `mtu` 的限制。
- 可以先对设备指定特征进行监听，再请求连接。内部会自动在设备连接完成之后建立真正的监听，并在断开重连之后重新将添加监听。使得上层业务逻辑开发过程更加简便。
- 搜索外围设备广播过程中，可以根据 `manufacturer` 值进行设备的过滤。

## 使用
### 初始化
可以通过如下方式设定日志级别，以及初始化 `ble_ex` 库。
```dart
WidgetsFlutterBinding.ensureInitialized();

BleEx.logLevel = BleLogLevel.lib;
var bleex = BleEx();
```
### 扫描外围设备
搜索设备提供了两种方式

监听周围所有设备的变化：
```dart
var task = bleex.createScanningTask();
task.addDeviceUpdateListener(deviceUpdateHandler);
task.scanDevices({List<DevicesFilter>? filters});

void deviceUpdateHandler(DiscoveredDevice device) {
}

// 停止扫描设备，停止后可以重新开启
task.stopScan();
// 释放，释放后则不能在开启
task.dispose();


```

直接搜索并获取某个指定的设备：
```dart
var device = await bleex.searchForDevice(List<DevicesFilter> filters)
// device 就是查找到的指定的外围设备
```

### 设备的连接与状态
你可以通过如下方式建立或断开设备之间的连接，并监听连接状态的变化。

```dart
BlePeripheral peripheral = bleex.<T extends BlePeripheral>(DiscoveredDevice device, T instance);
peripheral.addConnectedListener(connectedHandler);
peripheral.addDisconnectedListener(disconnectedHandler);
peripheral.addConnectErrorListener(connectErrorHandler);
// 主动建立连接
peripheral.connect();
// 主动断开连接
// await peripheral.disconnect();

void connectedHandler(BlePeripheral target) {
    // 设备已连接
}

void disconnectedHandler(BlePeripheral target) {
    // 设备断开
}

void connectErrorHandler(BlePeripheral target, Object error) {
    // 设备连接错误
}
```

### 特征的读与写
#### 读取特征
```dart
try {
    Uint8List response = await peripheral.read(Uuid service, Uuid characteristic);
    // 有应答写完成
} catch (e) {
    // 有应答写错误
}
```
#### 有应答写入特征
```dart
try {
    await peripheral.writeWithResponse(Uuid service, Uuid characteristic, Uint8List data);
    // 有应答写完成
} catch (e) {
    // 有应答写错误
}
```
#### 无应答写入特征
```dart
try {
    await peripheral.writeWithoutResponse(Uuid service, Uuid characteristic, Uint8List data);
    // 无应答写完成
} catch (e) {
    // 无应答写错误
}
```
### 监听指定特征的通知
```dart
peripheral.addNotifyListener(Uuid characteristic, nofityHandler);
void nofityHandler(BlePeripheral target, Uuid service, Uuid characteristic,Uint8List data) {
    // 接收到了某个特征的通知
}
```
### 短数据请求(受到mtu限制)
```dart
try {
    var response = await peripheral.request(Uuid service, Uuid characteristic, Uint8List data);
    // response 为接收到的数据
} catch (e) {
    // 请求失败
}
```
### 协商请求最大的mtu
```dart
int suggestedMtu = await peripheral.requestSuggestedMtu();
```
### 请求优先级，仅在android上生效
应在 requestSuggestedMtu 调用结束之后再调用，因为 requestSuggestedMtu 在某些设备上可能会触发断连并自动重连的过程
```dart
await peripheral.requestConnectionPriority(ConnectionPriority priority);
```
### 长数据的写(不受mtu限制)
```dart
try {
    await peripheral.writeLarge(Uuid service, Uuid characteristic, Uint8List bytes);
    // 长数据写入完成
} catch (e) {
    // 长数据写入错误
}
```
### 监听/移除监听指定特征的长数据(不受mtu限制)
```dart
peripheral.addLargeIndicateListener(Uuid service, Uuid characteristic, NotifyListener listener);
peripheral.removeLargeIndicateListener(Uuid service, Uuid characteristic, NotifyListener listener);
void largeIndicateHandler(BlePeripheral target, Uuid service, Uuid characteristic,Uint8List data) {
    // 接收到了某个特征的长数据
}
```
### 长数据请求(不受mtu限制)
```dart
try {
    var response = await peripheral.requestLarge(Uuid service, Uuid characteristic, Uint8List data);
    // response 为接收到的数据
} catch (e) {
    // 请求失败
}
```