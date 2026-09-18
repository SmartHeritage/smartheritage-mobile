import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import 'mock_data.dart';

/// Nguồn hiện vật và khu trưng bày cho toàn app.
///
/// Khởi đầu bằng [MockData] để màn hình đầu tiên không bao giờ trống, rồi
/// [refresh] thay bằng dữ liệu thật. Mất mạng thì giữ nguyên mock và bật
/// [isOffline] — app vẫn tham quan được, chỉ là dữ liệu cũ.
class ArtifactRepository extends ChangeNotifier {
  ArtifactRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  static final ArtifactRepository instance = ArtifactRepository();

  final ApiClient _api;

  List<Artifact> _artifacts = MockData.artifacts;
  List<String> _zones = _zonesFrom(MockData.artifacts);
  bool _isLoading = false;
  bool _isOffline = false;
  bool _loadedOnce = false;

  List<Artifact> get artifacts => _artifacts;

  /// Tên các khu trưng bày, đã có sẵn mục 'Tất cả' ở đầu.
  List<String> get zones => _zones;

  bool get isLoading => _isLoading;

  /// Đang hiển thị dữ liệu mock vì không gọi được backend.
  bool get isOffline => _isOffline;

  /// Tra theo id, `null` nếu không có.
  ///
  /// Id lưu dưới máy (yêu thích, lịch sử tham quan) là id của lần chạy trước —
  /// sau khi chuyển sang UUID của backend thì có thể không còn khớp. Bên gọi
  /// phải bỏ qua những id lạ chứ đừng hiển thị nhầm hiện vật khác.
  Artifact? tryById(String id) {
    for (final a in _artifacts) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Dùng khi bắt buộc phải có một hiện vật để hiển thị (mở từ thông báo,
  /// từ beacon). Không tìm thấy thì lấy hiện vật đầu danh sách.
  Artifact byId(String id) =>
      tryById(id) ??
      (_artifacts.isEmpty ? MockData.artifacts.first : _artifacts.first);

  /// Nạp sẵn danh sách cho widget test, không đụng mạng.
  @visibleForTesting
  void setArtifactsForTest(List<Artifact> artifacts) {
    _artifacts = artifacts;
    _zones = _zonesFrom(artifacts);
    _loadedOnce = true;
    notifyListeners();
  }

  /// Trả về dữ liệu mock ban đầu sau mỗi test.
  @visibleForTesting
  void resetForTest() {
    _artifacts = MockData.artifacts;
    _zones = _zonesFrom(MockData.artifacts);
    _loadedOnce = false;
    _isOffline = false;
  }

  /// Tải lần đầu; gọi lại nhiều lần không tốn thêm request.
  Future<void> ensureLoaded() async {
    if (_loadedOnce || _isLoading) return;
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Hai request độc lập — chạy song song để trang chủ đỡ chờ hai lượt.
      final results = await Future.wait([
        _api.get('/artifacts'),
        _api.get('/zones'),
      ]);

      final rawArtifacts = results[0];
      if (rawArtifacts is List && rawArtifacts.isNotEmpty) {
        _artifacts = rawArtifacts
            .whereType<Map<String, dynamic>>()
            .map(Artifact.fromJson)
            .toList();
      }

      final rawZones = results[1];
      if (rawZones is List && rawZones.isNotEmpty) {
        final names = rawZones
            .whereType<Map<String, dynamic>>()
            .map((z) => (z['name'] as String?) ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
        // Hiện vật ngoài trời có thể mang zone không nằm trong bảng zones —
        // gộp thêm để bộ lọc bản đồ không bỏ sót hiện vật nào.
        for (final a in _artifacts) {
          if (a.zone.isNotEmpty && !names.contains(a.zone)) names.add(a.zone);
        }
        _zones = ['Tất cả', ...names];
      } else {
        _zones = _zonesFrom(_artifacts);
      }

      _isOffline = false;
      _loadedOnce = true;
    } on ApiException catch (e) {
      // Lỗi mạng: giữ nguyên dữ liệu đang có. Lỗi 4xx/5xx cũng vậy — không có
      // lý do gì để xoá trắng màn hình vì một lần gọi hỏng.
      _isOffline = e.isNetwork;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static List<String> _zonesFrom(List<Artifact> artifacts) {
    final names = <String>[];
    for (final a in artifacts) {
      if (a.zone.isNotEmpty && !names.contains(a.zone)) names.add(a.zone);
    }
    return ['Tất cả', ...names];
  }
}
