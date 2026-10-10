import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import 'attraction.dart';
import 'mock_data.dart';

/// Nguồn hiện vật, điểm tham quan và khu du lịch cho toàn app.
///
/// Khởi đầu bằng [MockData] để màn hình đầu tiên không bao giờ trống, rồi
/// [refresh] thay bằng dữ liệu thật. Mất mạng thì giữ nguyên mock và bật
/// [isOffline] — app vẫn tham quan được, chỉ là dữ liệu cũ.
class ArtifactRepository extends ChangeNotifier {
  ArtifactRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  static ArtifactRepository _instance = ArtifactRepository();

  static ArtifactRepository get instance => _instance;

  /// Thay kho dùng chung bằng bản chạy trên ApiClient giả cho widget test.
  @visibleForTesting
  static set instance(ArtifactRepository repository) => _instance = repository;

  final ApiClient _api;

  List<Artifact> _artifacts = MockData.artifacts;
  List<Attraction> _attractions = const [];
  List<TourismArea> _areas = const [];
  List<String> _availableLanguages = const [];
  bool _isLoading = false;
  bool _isOffline = false;
  bool _loadedOnce = false;

  /// Ngôn ngữ khách chọn, gửi kèm `?language=` để backend trả nội dung và
  /// thuyết minh đúng thứ tiếng. `null` thì backend tự dùng ngôn ngữ ưa thích
  /// của tài khoản (hoặc mặc định). Đổi xong phải [refresh].
  String? language;

  List<Artifact> get artifacts => _artifacts;

  /// Điểm tham quan từ `GET /attractions`.
  List<Attraction> get attractions => _attractions;

  /// Khu du lịch (`GET /tourism-areas`) — chọn ở thanh tiêu đề tab Bản đồ.
  List<TourismArea> get tourismAreas => _areas;

  /// Khu du lịch chứa điểm tham quan [attractionId], `null` nếu không rõ.
  String? areaIdOf(String? attractionId) {
    if (attractionId == null) return null;
    for (final a in _attractions) {
      if (a.id == attractionId) return a.tourismAreaId;
    }
    return null;
  }

  /// Hiện vật thuộc khu [areaId]. `null` = mọi hiện vật (chưa có dữ liệu khu,
  /// hoặc đang chạy mock).
  List<Artifact> artifactsInArea(String? areaId) => areaId == null
      ? _artifacts
      : _artifacts.where((a) => areaIdOf(a.attractionId) == areaId).toList();

  /// Các ngôn ngữ backend có nội dung, gộp từ `language.available` của từng
  /// hiện vật. Rỗng khi chưa tải được.
  List<String> get availableLanguages => _availableLanguages;

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
    _loadedOnce = true;
    notifyListeners();
  }

  /// Trả về dữ liệu mock ban đầu sau mỗi test.
  @visibleForTesting
  void resetForTest() {
    _artifacts = MockData.artifacts;
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
      // Backend đã bỏ Zone (`GET /zones` giờ là 404); nhóm hiện vật bây giờ là
      // Attraction → TourismArea. Các request chạy song song, nhưng
      // /attractions và /tourism-areas là phụ — hỏng thì nuốt lỗi, không được
      // kéo cả danh sách hiện vật đổ theo.
      final artifactsFuture = _fetchArtifacts();
      final attractionsFuture = _optional('/attractions');
      final areasFuture = _optional('/tourism-areas');

      final rawArtifacts = await artifactsFuture;
      final rawAttractions = await attractionsFuture;
      final rawAreas = await areasFuture;

      if (rawAttractions is List) {
        _attractions = rawAttractions
            .whereType<Map<String, dynamic>>()
            .where((a) => a['id'] is String)
            .map(Attraction.fromJson)
            .toList();
      }
      final attractionNames = {
        for (final a in _attractions)
          if (a.name.isNotEmpty) a.id: a.name,
      };

      if (rawAreas is List) {
        _areas = rawAreas
            .whereType<Map<String, dynamic>>()
            .map(TourismArea.fromJson)
            .where((a) => a.id.isNotEmpty)
            .toList();
      }

      if (rawArtifacts is List && rawArtifacts.isNotEmpty) {
        final maps = rawArtifacts.whereType<Map<String, dynamic>>().toList();
        _artifacts = maps
            .map((j) => Artifact.fromJson(j, attractionNames: attractionNames))
            .toList();
        _availableLanguages = {
          for (final j in maps)
            if (j['language'] case {'available': final List codes})
              ...codes.whereType<String>(),
        }.toList();
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

  /// Sơ đồ của một điểm tham quan: beacon và hiện vật kèm vị trí trên sơ đồ
  /// tầng. Hiện vật lấy bản đầy đủ trong danh mục nếu có.
  Future<AttractionMap> fetchAttractionMap(String attractionId) async {
    final lang = language;
    final data = await _api.get(
      '/attractions/$attractionId/map',
      query: lang == null ? null : {'language': lang},
    );
    if (data is! Map<String, dynamic>) {
      throw ApiException('Máy chủ trả về dữ liệu không hợp lệ.');
    }
    return AttractionMap.fromJson(data, lookup: tryById);
  }

  /// Ảnh của hiện vật (`GET /artifacts/:id/media`, loại IMAGE và
  /// GALLERY_IMAGE), theo đúng thứ tự backend sắp. Hiện vật mock (id không phải
  /// UUID) thì không có gì để hỏi.
  Future<List<GalleryImage>> fetchImages(String artifactId) async {
    if (!_uuid.hasMatch(artifactId)) return const [];
    final lang = language;
    final data = await _api.get(
      '/artifacts/$artifactId/media',
      query: lang == null ? null : {'language': lang},
    );
    if (data is! List) return const [];
    return [
      for (final m in data.whereType<Map<String, dynamic>>())
        if ((m['type'] == 'IMAGE' || m['type'] == 'GALLERY_IMAGE') &&
            Artifact.resolveMediaUrl(m['url'] as String?) != null)
          GalleryImage(
            url: Artifact.resolveMediaUrl(m['url'] as String?)!,
            caption: m['caption'] as String?,
          ),
    ];
  }

  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// `GET /artifacts` theo [language]. Backend trả 400 khi mã ngôn ngữ không
  /// có trong Language Registry — khi đó lấy theo mặc định còn hơn trắng màn.
  Future<dynamic> _fetchArtifacts() async {
    final lang = language;
    if (lang == null) return _api.get('/artifacts');
    try {
      return await _api.get('/artifacts', query: {'language': lang});
    } on ApiException catch (e) {
      if (e.statusCode != 400) rethrow;
      return _api.get('/artifacts');
    }
  }

  /// Dữ liệu phụ (điểm tham quan, khu du lịch): hỏng thì bỏ qua, không được
  /// kéo danh sách hiện vật đổ theo.
  Future<dynamic> _optional(String path) =>
      _api.get(path).then<dynamic>((v) => v, onError: (_) => null);
}

/// Một ảnh trong thư viện ảnh của hiện vật.
class GalleryImage {
  const GalleryImage({required this.url, this.caption});

  final String url;
  final String? caption;
}
