import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Mã ẩn danh của máy, gửi kèm mỗi lượt quét beacon (`POST /scans`).
///
/// Backend dùng nó để đếm khách (kể cả khách chưa đăng nhập) và ước lượng mức
/// đông người — nên phải ổn định qua các lần mở app, nhưng không gắn với
/// danh tính nào. Định dạng theo `RecordScanDto.deviceId`: 8–64 ký tự chữ, số
/// hoặc gạch ngang.
class DeviceId {
  DeviceId._();

  static const _key = 'device.id';

  static String? _cached;

  static Future<String> get() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null || !_valid.hasMatch(id)) {
      id = _generate();
      await prefs.setString(_key, id);
    }
    return _cached = id;
  }

  static final _valid = RegExp(r'^[A-Za-z0-9-]{8,64}$');

  /// UUID v4 dạng chuỗi — đủ ngẫu nhiên, đúng định dạng backend nhận.
  static String _generate() {
    final rnd = Random.secure();
    final b = List<int>.generate(16, (_) => rnd.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String hex(int from, int to) => b
        .sublist(from, to)
        .map((x) => x.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
