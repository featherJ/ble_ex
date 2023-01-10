import 'package:ble_ex/ble_ex.dart';

class BleUUIDs {
  /// The uuid of service
  static final Uuid service =
      Uuid.parse("10000000-0000-0000-0000-000000000000");

  static final Uuid service2 =
      Uuid.parse("10000000-0002-0000-0000-000000000000");

  /// A uuid of characteristic used to authenticate the central device
  static final Uuid verifyCentral =
      Uuid.parse("10000001-0000-0000-0000-000000000000");

  /// A uuid of characteristic used to test notifying from peripheral device
  static final Uuid baseNotifyTest =
      Uuid.parse("10000002-0000-0000-0000-000000000000");
  static final Uuid baseNotifyResultTest =
      Uuid.parse("10000002-0001-0000-0000-000000000000");

  // /A uuid of characteristic used to test reading from peripheral
  static final Uuid baseReadTest =
      Uuid.parse("10000003-0000-0000-0000-000000000000");

  /// A uuid of characteristic used to test writing from peripheral
  static final Uuid baseWriteTest =
      Uuid.parse("10000004-0000-0000-0000-000000000000");

  /// A uuid of characteristic used to test requesting data under mtu limited from peripheral device
  static final Uuid requestDataTest =
      Uuid.parse("10000005-0000-0000-0000-000000000000");

  ///A uuid of characteristic used to test receiving large data from central device
  static final Uuid writeLargeDataToPeripheralTest =
      Uuid.parse("10000006-0000-0000-0000-000000000000");

  /// A uuid of characteristic used to test writing large data to central device
  static final Uuid writeLargeDataToCentralTest =
      Uuid.parse("10000007-0000-0000-0000-000000000000");

  /// A uuid of characteristic used to test requesting large data from peripheral device
  static final Uuid requestLargeDataTest =
      Uuid.parse("10000008-0000-0000-0000-000000000000");
}
