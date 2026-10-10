import 'dart:async';
import 'dart:io';

import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../data/beacon_repository.dart';
import 'location_service.dart';

/// Một beacon nghe được trong một nhịp quét.
class HeardBeacon {
  const HeardBeacon({
    required this.identity,
    required this.distanceMeters,
    this.rssi,
  });

  final BeaconIdentity identity;

  /// Khoảng cách ước lượng (mét) từ RSSI và txPower; âm = không ước lượng được.
  final double distanceMeters;
  final int? rssi;
}

/// Nguồn tín hiệu beacon. Tách thành interface để test thay được Bluetooth.
abstract class BeaconSource {
  /// Bắt đầu quét; mỗi nhịp gọi [onHeard] với các beacon nghe được.
  /// Trả về thông báo lỗi (tiếng Việt, hiện thẳng cho khách) nếu không quét
  /// được — thiếu quyền, Bluetooth tắt…; `null` khi đã chạy.
  Future<String?> start(void Function(List<HeardBeacon> heard) onHeard);

  Future<void> stop();
}

/// Quét iBeacon thật qua `dchs_flutter_beacon`: CoreLocation trên iOS,
/// AltBeacon trên Android.
///
/// iOS chỉ quét được các proximity UUID khai báo trước ([AppConfig.beaconUuids]).
class IBeaconScanner implements BeaconSource {
  StreamSubscription<RangingResult>? _ranging;

  /// Thiết bị có Bluetooth/CoreLocation để quét không (iOS/Android thật).
  static bool get isSupported => Platform.isIOS || Platform.isAndroid;

  @override
  Future<String?> start(void Function(List<HeardBeacon> heard) onHeard) async {
    try {
      final problem = Platform.isIOS
          ? await _prepareIOS()
          : await _prepareAndroid();
      if (problem != null) return problem;

      // Giữ beacon trong kết quả thêm vài giây giữa các nhịp quét, để một gói
      // tin lỡ nhịp không làm hiện vật "biến mất" rồi xuất hiện lại.
      if (Platform.isAndroid) {
        await flutterBeacon.setUseTrackingCache(true);
        await flutterBeacon.setMaxTrackingAge(10000);
      }

      final regions = [
        for (final uuid in AppConfig.beaconUuids)
          Region(identifier: 'smartheritage-$uuid', proximityUUID: uuid),
      ];
      await _ranging?.cancel();
      _ranging = flutterBeacon.ranging(regions).listen((result) {
        onHeard([
          for (final b in result.beacons)
            HeardBeacon(
              identity: BeaconIdentity(
                proximityUuid: b.proximityUUID,
                major: b.major,
                minor: b.minor,
              ),
              distanceMeters: b.accuracy,
              rssi: b.rssi,
            ),
        ]);
      }, onError: (Object _) {
        // Một nhịp quét lỗi (Bluetooth chập chờn) thì bỏ qua nhịp đó — nhịp
        // sau vẫn tới, không đáng làm hỏng cả phiên quét.
      });
      return null;
    } on PlatformException catch (e) {
      return 'Không khởi động được bộ quét beacon (${e.message ?? e.code}).';
    }
  }

  /// iOS: không dùng `initializeAndCheckScanning` của plugin. Bản 0.6.10 trả
  /// `nil` khi thành công nên phía Dart đọc thành `false`, và lần chạy đầu nó
  /// báo "chưa xác định quyền" trước cả khi hộp thoại xin quyền kịp hiện.
  /// Nên tự làm từng bước: xin quyền vị trí → khởi tạo → chờ Bluetooth.
  Future<String?> _prepareIOS() async {
    switch (await LocationService.ensurePermission()) {
      case LocationStatus.serviceDisabled:
        return 'Hãy bật Dịch vụ định vị trong Cài đặt để quét beacon.';
      case LocationStatus.denied:
      case LocationStatus.deniedForever:
        return 'Ứng dụng cần quyền vị trí để nhận tín hiệu beacon. '
            'Hãy bật trong Cài đặt.';
      case LocationStatus.granted:
        break;
    }
    await flutterBeacon.setLocationAuthorizationTypeDefault(
      AuthorizationStatus.whenInUse,
    );
    await flutterBeacon.initializeScanning;
    return _bluetoothProblem(await _settledBluetoothState());
  }

  /// Android: plugin tự xin quyền (vị trí, BLUETOOTH_SCAN) và trả đúng
  /// `true`/`false`.
  Future<String?> _prepareAndroid() async {
    final ready = await flutterBeacon.initializeAndCheckScanning;
    final problem = _bluetoothProblem(await flutterBeacon.bluetoothState);
    if (problem != null) return problem;

    final auth = await flutterBeacon.authorizationStatus;
    if (auth.value == 'DENIED' || auth.value == 'RESTRICTED') {
      return 'Ứng dụng cần quyền vị trí để nhận tín hiệu beacon. '
          'Hãy bật trong Cài đặt.';
    }
    if (!await flutterBeacon.checkLocationServicesIfEnabled) {
      return 'Hãy bật Dịch vụ vị trí (GPS) — Android cần nó để quét beacon.';
    }
    if (!ready) return 'Chưa khởi động được bộ quét beacon.';
    return null;
  }

  /// Lần đầu bật, iOS đang hiện hộp thoại xin quyền Bluetooth nên trạng thái
  /// là "unknown" cho tới khi khách trả lời. Mỗi lần hỏi plugin chờ tối đa 2
  /// giây — hỏi lại tới khoảng 30 giây.
  Future<BluetoothState> _settledBluetoothState() async {
    var state = await flutterBeacon.bluetoothState;
    for (
      var i = 0;
      i < 15 &&
          (state.value == 'STATE_UNKNOWN' || state.value == 'STATE_RESETTING');
      i++
    ) {
      state = await flutterBeacon.bluetoothState;
    }
    return state;
  }

  String? _bluetoothProblem(BluetoothState state) => switch (state.value) {
    'STATE_OFF' || 'STATE_TURNING_OFF' => 'Hãy bật Bluetooth để quét beacon.',
    'STATE_UNAUTHORIZED' =>
      'Ứng dụng chưa được phép dùng Bluetooth. Hãy bật trong Cài đặt.',
    'STATE_UNSUPPORTED' => 'Thiết bị này không hỗ trợ Bluetooth Low Energy.',
    'STATE_UNKNOWN' ||
    'STATE_RESETTING' => 'Bluetooth chưa sẵn sàng. Hãy thử bật quét lại.',
    _ => null,
  };

  @override
  Future<void> stop() async {
    await _ranging?.cancel();
    _ranging = null;
  }
}
