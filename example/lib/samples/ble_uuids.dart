import 'package:ble_ex/ble_ex.dart';

class BleUUIDs {
  /* --------------- service uuid --------------- */

  /// The uuid of service 1
  static final Uuid service1 =
      Uuid.parse("10000000-0001-0000-0000-000000000000");

  /// The uuid of service 2
  static final Uuid service2 =
      Uuid.parse("10000000-0002-0000-0000-000000000000");

  /// A uuid of characteristic used to authenticate the central device
  static final Uuid verifyCentral =
      Uuid.parse("10000000-1010-0000-0000-000000000000");

  /* --------------- base characteristics --------------- */

  /// A uuid of characteristic used to test reading from peripheral
  static final Uuid readTest =
      Uuid.parse("10000001-0001-0000-0000-000000000000");

  /// A uuid of characteristic used to test writing from peripheral
  static final Uuid writeTest =
      Uuid.parse("10000001-0002-0000-0000-000000000000");

  /// A uuid of characteristic used to test indicate from peripheral device
  static final Uuid notifyTest =
      Uuid.parse("10000001-0003-0000-0000-000000000000");

  /// A uuid of characteristic used to test indicate from peripheral device
  static final Uuid indicateTest =
      Uuid.parse("10000001-0004-0000-0000-000000000000");

  /* --------------- bleex characteristics --------------- */

  /// A uuid of characteristic used to test requesting data under mtu limited from peripheral device
  static final Uuid requestTest =
      Uuid.parse("10000002-0001-0000-0000-000000000000");

  /// A uuid of characteristic used to test requesting large data from peripheral device
  static final Uuid requestLargeTest =
      Uuid.parse("10000002-0002-0000-0000-000000000000");

  ///A uuid of characteristic used to test receiving large data from central device
  static final Uuid writeLargeTest =
      Uuid.parse("10000002-0003-0000-0000-000000000000");

  /// A uuid of characteristic used to test writing large data to central device
  static final Uuid indicateLargeTest =
      Uuid.parse("10000002-0004-0000-0000-000000000000");
}
