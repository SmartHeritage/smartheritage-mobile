import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/artifact_repository.dart';
import '../data/mock_data.dart';
import '../l10n/l10n.dart';
import '../services/api_client.dart';
import 'auth_state.dart';

/// Lịch sử tham quan.
///
/// Chỉ ghi khi **iBeacon phát hiện** hiện vật — không ghi khi khách tự bấm vào
/// hiện vật trong app.
///
/// Hai nguồn:
/// - **Khách**: lưu cục bộ trên máy ([SharedPreferences]).
/// - **Đã đăng nhập**: đọc `GET /visits` của backend. Lượt ghé được backend tự
///   ghi qua `POST /scans` (xem `BeaconScanController`), nên ở đây chỉ chèn
///   trước một dòng cho giao diện phản hồi ngay. Xoá thì gọi `DELETE /visits`.
class VisitHistoryController extends ChangeNotifier {
  VisitHistoryController._();

  static final VisitHistoryController instance = VisitHistoryController._();

  static const _key = 'visit_history_v1';
  static const _maxItems = 50;

  ApiClient _api = ApiClient.instance;

  @visibleForTesting
  set apiForTest(ApiClient api) => _api = api;

  final List<_Visit> _visits = []; // mới nhất ở đầu
  bool _loaded = false;

  /// Lịch sử trên server; `null` khi chưa đăng nhập (hoặc chưa tải được).
  List<_ServerVisit>? _server;
  bool _wasLoggedIn = false;

  /// Đang hiển thị lịch sử của tài khoản (server) thay vì của máy.
  bool get isAccountHistory => _server != null;

  /// Danh sách bản ghi (mới nhất trước) để hiển thị.
  ///
  /// Bỏ qua id không còn tồn tại (dữ liệu lưu từ lần chạy trước, hoặc hiện vật
  /// đã bị gỡ khỏi backend) — thà thiếu một dòng còn hơn hiện nhầm hiện vật.
  List<VisitRecord> get records {
    final server = _server;
    if (server != null) {
      return [
        for (final v in server)
          VisitRecord(
            artifact: v.artifact,
            dateLabel: _dateLabel(v.time),
            timeLabel: _timeLabel(v.time),
          ),
      ];
    }
    return _visits
        .map((v) {
          final artifact = ArtifactRepository.instance.tryById(v.id);
          if (artifact == null) return null;
          return VisitRecord(
            artifact: artifact,
            dateLabel: _dateLabel(v.time),
            timeLabel: _timeLabel(v.time),
          );
        })
        .whereType<VisitRecord>()
        .toList();
  }

  bool get isEmpty => _server?.isEmpty ?? _visits.isEmpty;

  int get artifactCount => _visits.map((v) => v.id).toSet().length;

  int get zoneCount => _visits
      .map((v) => ArtifactRepository.instance.tryById(v.id)?.zone)
      .whereType<String>()
      .toSet()
      .length;

  /// Số liệu `GET /visits/stats` của tài khoản; `null` khi chưa tải được.
  VisitStats? _serverStats;

  /// Ba con số đầu màn Lịch sử.
  ///
  /// Đăng nhập: lấy từ backend — tính trên toàn bộ lịch sử, không bị giới hạn
  /// [_maxItems] dòng như danh sách. Chưa tải được thì tạm tính từ các dòng
  /// đang có. Khách: tính từ lịch sử trên máy; máy chỉ giữ lần ghé gần nhất của
  /// mỗi hiện vật nên "ngày tham quan" có thể thấp hơn thực tế.
  VisitStats get stats {
    if (_server != null && _serverStats != null) return _serverStats!;
    final rows = records;
    String dayKey(DateTime t) => '${t.year}-${t.month}-${t.day}';
    final times = _server?.map((v) => v.time) ?? _visits.map((v) => v.time);
    return VisitStats(
      artifactsViewed: rows.map((r) => r.artifact.id).toSet().length,
      visitDays: times.map(dayKey).toSet().length,
      attractionsVisited: rows
          .map((r) => r.artifact.attractionId)
          .whereType<String>()
          .toSet()
          .length,
    );
  }

  /// Tải lại `GET /visits/stats`. Gọi khi mở màn Lịch sử: lượt ghé do
  /// `POST /scans` ghi ở nơi khác nên số trên server có thể đã đổi.
  /// Lỗi thì giữ số cũ — thống kê là thông tin phụ.
  Future<void> refreshStats() async {
    if (!AuthController.instance.isLoggedIn) return;
    try {
      final data = await _api.get('/visits/stats');
      if (data is! Map<String, dynamic> || !AuthController.instance.isLoggedIn) {
        return;
      }
      _serverStats = VisitStats.fromJson(data);
      notifyListeners();
    } on ApiException {
      // giữ nguyên
    }
  }

  /// Nạp lịch sử đã lưu. Gọi một lần khi khởi động app.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    _visits
      ..clear()
      ..addAll(raw.map(_Visit.tryDecode).whereType<_Visit>());
    notifyListeners();

    AuthController.instance.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  /// Đăng nhập thì chuyển sang lịch sử của tài khoản; đăng xuất thì quay về
  /// lịch sử trên máy — lịch sử của người trước không được ở lại.
  void _onAuthChanged() {
    final loggedIn = AuthController.instance.isLoggedIn;
    if (loggedIn == _wasLoggedIn) return;
    _wasLoggedIn = loggedIn;
    if (loggedIn) {
      syncFromServer();
    } else {
      _server = null;
      _serverStats = null;
      notifyListeners();
    }
  }

  /// Tải `GET /visits`. Lỗi thì giữ nguyên những gì đang hiển thị.
  Future<void> syncFromServer() async {
    unawaited(refreshStats());
    try {
      final data = await _api.get('/visits', query: {'limit': '$_maxItems'});
      if (data is! List || !AuthController.instance.isLoggedIn) return;
      _server = data
          .whereType<Map<String, dynamic>>()
          .map(_ServerVisit.fromJson)
          .whereType<_ServerVisit>()
          .toList();
      notifyListeners();
    } on ApiException {
      // Mất mạng: vẫn hiện lịch sử trên máy, lần đăng nhập sau thử lại.
    }
  }

  /// Ghi nhận một lần beacon phát hiện hiện vật.
  Future<void> recordBeaconVisit(Artifact artifact) async {
    _visits.removeWhere((v) => v.id == artifact.id); // gộp trùng → đưa lên đầu
    _visits.insert(0, _Visit(id: artifact.id, time: DateTime.now()));
    if (_visits.length > _maxItems) {
      _visits.removeRange(_maxItems, _visits.length);
    }
    // Backend đã/đang ghi lượt này qua POST /scans; chèn trước để màn hình
    // không phải chờ một vòng GET /visits. Cùng hiện vật trong ngày là một
    // dòng — đúng như backend gộp.
    final server = _server;
    if (server != null) {
      final now = DateTime.now();
      server.removeWhere(
          (v) => v.artifact.id == artifact.id && _sameDay(v.time, now));
      server.insert(0, _ServerVisit(artifact, now));
    }
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _visits.clear();
    final hadServer = _server != null;
    if (hadServer) {
      _server = [];
      _serverStats = const VisitStats();
    }
    notifyListeners();
    await _persist();
    if (hadServer) {
      try {
        await _api.delete('/visits');
      } on ApiException {
        // Xoá trên server hỏng thì nạp lại để màn hình nói thật.
        await syncFromServer();
      }
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _visits.map((v) => v.encode()).toList());
  }

  String _dateLabel(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return appStrings.today;
    if (diff == 1) return appStrings.yesterday;
    return '${_two(t.day)}/${_two(t.month)}/${t.year}';
  }

  String _timeLabel(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

  String _two(int n) => n.toString().padLeft(2, '0');
}

/// Ba ô thống kê lịch sử — đúng shape `GET /visits/stats`.
class VisitStats {
  const VisitStats({
    this.artifactsViewed = 0,
    this.visitDays = 0,
    this.attractionsVisited = 0,
  });

  factory VisitStats.fromJson(Map<String, dynamic> json) {
    int read(String key) => (json[key] as num?)?.toInt() ?? 0;
    return VisitStats(
      artifactsViewed: read('artifactsViewed'),
      visitDays: read('visitDays'),
      attractionsVisited: read('attractionsVisited'),
    );
  }

  final int artifactsViewed;
  final int visitDays;
  final int attractionsVisited;
}

class _Visit {
  const _Visit({required this.id, required this.time});

  final String id;
  final DateTime time;

  String encode() => '$id|${time.millisecondsSinceEpoch}';

  static _Visit? tryDecode(String raw) {
    final parts = raw.split('|');
    if (parts.length != 2) return null;
    final millis = int.tryParse(parts[1]);
    if (millis == null) return null;
    return _Visit(
      id: parts[0],
      time: DateTime.fromMillisecondsSinceEpoch(millis),
    );
  }
}

/// Một dòng của `GET /visits`: mỗi hiện vật một dòng mỗi ngày.
class _ServerVisit {
  _ServerVisit(this.artifact, this.time);

  static _ServerVisit? fromJson(Map<String, dynamic> json) {
    final id = json['artifactId'] as String?;
    if (id == null) return null;
    // Ưu tiên bản đầy đủ trong danh mục; hiện vật đã gỡ khỏi danh mục vẫn hiện
    // được tên và ảnh mà backend gửi kèm.
    final artifact = ArtifactRepository.instance.tryById(id) ??
        Artifact.fromJson({
          'id': id,
          'name': json['artifactName'],
          'imageUrl': json['imageUrl'],
        });
    final time = DateTime.tryParse((json['lastScannedAt'] as String?) ?? '')
            ?.toLocal() ??
        DateTime.tryParse((json['visitedOn'] as String?) ?? '') ??
        DateTime.now();
    return _ServerVisit(artifact, time);
  }

  final Artifact artifact;
  final DateTime time;
}
