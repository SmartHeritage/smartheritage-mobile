import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import 'mock_data.dart';

/// Danh sách hiện vật yêu thích, lưu trên server theo tài khoản.
///
/// Trước đây đây là một `Set<String>` trong bộ nhớ: bấm tim thì đổi icon và
/// báo "đã lưu", nhưng không lưu ở đâu cả và mở lại app là mất.
///
/// Yêu thích gắn với tài khoản nên khách chưa đăng nhập không có gì để đồng
/// bộ — [load] và [toggle] chỉ có nghĩa sau khi đăng nhập.
class FavoriteRepository extends ChangeNotifier {
  FavoriteRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  static FavoriteRepository? _instance;

  static FavoriteRepository get instance => _instance ??= FavoriteRepository();

  @visibleForTesting
  static set instance(FavoriteRepository repository) => _instance = repository;

  final ApiClient _api;

  List<Artifact> _artifacts = const [];
  Set<String> _ids = const {};
  bool _isLoading = false;

  /// Hiện vật yêu thích, đầy đủ thông tin do `GET /favorites` trả về.
  List<Artifact> get artifacts => _artifacts;

  Set<String> get ids => _ids;

  bool get isLoading => _isLoading;

  bool isFavorite(String artifactId) => _ids.contains(artifactId);

  /// Nạp danh sách từ server. Gọi sau khi đăng nhập hoặc khôi phục phiên.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.get('/favorites');
      if (data is List) {
        _artifacts = data
            .whereType<Map<String, dynamic>>()
            .map(Artifact.fromJson)
            .toList();
        _ids = _artifacts.map((a) => a.id).toSet();
      }
    } on ApiException {
      // Mất mạng hoặc phiên hết hạn: giữ nguyên những gì đang có. Đăng xuất
      // thật sự thì [clear] mới là nơi xoá.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Bật/tắt yêu thích cho [artifact].
  ///
  /// Cập nhật giao diện trước rồi mới gọi mạng — bấm tim phải phản hồi ngay.
  /// Request hỏng thì hoàn tác và trả `false` để bên gọi báo lỗi; không thì
  /// trái tim đỏ lên trong khi server không hề lưu, đúng lỗi của bản cũ.
  Future<bool> toggle(Artifact artifact) async {
    final wasFavorite = isFavorite(artifact.id);
    _applyLocal(artifact, favorite: !wasFavorite);

    try {
      if (wasFavorite) {
        await _api.delete('/favorites/${artifact.id}');
      } else {
        await _api.put('/favorites/${artifact.id}');
      }
      return true;
    } on ApiException {
      _applyLocal(artifact, favorite: wasFavorite);
      return false;
    }
  }

  /// Về trạng thái khách. Gọi khi đăng xuất — dữ liệu của người này không
  /// được phép còn nằm đó cho người sau nhìn thấy.
  void clear() {
    _artifacts = const [];
    _ids = const {};
    notifyListeners();
  }

  void _applyLocal(Artifact artifact, {required bool favorite}) {
    final ids = Set<String>.from(_ids);
    final artifacts = List<Artifact>.from(_artifacts);
    if (favorite) {
      ids.add(artifact.id);
      if (!artifacts.any((a) => a.id == artifact.id)) artifacts.insert(0, artifact);
    } else {
      ids.remove(artifact.id);
      artifacts.removeWhere((a) => a.id == artifact.id);
    }
    _ids = ids;
    _artifacts = artifacts;
    notifyListeners();
  }
}
