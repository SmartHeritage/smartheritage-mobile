import 'package:geolocator/geolocator.dart';

/// Kết quả khi xin quyền vị trí.
enum LocationStatus {
  granted,
  serviceDisabled, // người dùng tắt GPS trên máy
  denied, // từ chối cấp quyền
  deniedForever, // từ chối vĩnh viễn (phải vào Cài đặt bật lại)
}

/// Bọc các thao tác định vị của `geolocator` cho gọn.
class LocationService {
  LocationService._();

  /// Kiểm tra GPS có bật và quyền đã được cấp chưa; nếu chưa thì hỏi người dùng.
  static Future<LocationStatus> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationStatus.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.denied:
        return LocationStatus.denied;
      case LocationPermission.deniedForever:
        return LocationStatus.deniedForever;
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationStatus.granted;
      case LocationPermission.unableToDetermine:
        return LocationStatus.denied;
    }
  }

  /// Lấy vị trí hiện tại một lần.
  ///
  /// Có giới hạn thời gian 12s; nếu quá lâu (hay gặp trên emulator) thì
  /// dùng tạm vị trí đã biết gần nhất để không bị treo mãi.
  static Future<Position> current() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      rethrow;
    }
  }

  /// Luồng vị trí cập nhật liên tục (mỗi khi di chuyển >= 3m).
  static Stream<Position> stream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    );
  }

  /// Khoảng cách (mét) giữa 2 toạ độ.
  static double distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}
