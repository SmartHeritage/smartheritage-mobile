import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/artifact_repository.dart';
import '../data/mock_data.dart';

/// Lịch sử tham quan lưu **cục bộ trên máy** (không cần đăng nhập).
///
/// Chỉ ghi khi **iBeacon phát hiện** hiện vật — không ghi khi khách tự bấm vào
/// hiện vật trong app. Dữ liệu tồn tại qua các lần mở app nhờ [SharedPreferences].
class VisitHistoryController extends ChangeNotifier {
  VisitHistoryController._();

  static final VisitHistoryController instance = VisitHistoryController._();

  static const _key = 'visit_history_v1';
  static const _maxItems = 50;

  final List<_Visit> _visits = []; // mới nhất ở đầu
  bool _loaded = false;

  /// Danh sách bản ghi (mới nhất trước) để hiển thị.
  ///
  /// Bỏ qua id không còn tồn tại (dữ liệu lưu từ lần chạy trước, hoặc hiện vật
  /// đã bị gỡ khỏi backend) — thà thiếu một dòng còn hơn hiện nhầm hiện vật.
  List<VisitRecord> get records => _visits
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

  bool get isEmpty => _visits.isEmpty;

  int get artifactCount => _visits.map((v) => v.id).toSet().length;

  int get zoneCount => _visits
      .map((v) => ArtifactRepository.instance.tryById(v.id)?.zone)
      .whereType<String>()
      .toSet()
      .length;

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
  }

  /// Ghi nhận một lần beacon phát hiện hiện vật.
  Future<void> recordBeaconVisit(Artifact artifact) async {
    _visits.removeWhere((v) => v.id == artifact.id); // gộp trùng → đưa lên đầu
    _visits.insert(0, _Visit(id: artifact.id, time: DateTime.now()));
    if (_visits.length > _maxItems) {
      _visits.removeRange(_maxItems, _visits.length);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _visits.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _visits.map((v) => v.encode()).toList());
  }

  String _dateLabel(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    return '${_two(t.day)}/${_two(t.month)}/${t.year}';
  }

  String _timeLabel(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

  String _two(int n) => n.toString().padLeft(2, '0');
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
