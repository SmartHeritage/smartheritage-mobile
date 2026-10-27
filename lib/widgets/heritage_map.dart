import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../l10n/l10n.dart';
import '../services/mapbox_config.dart';
import '../theme/app_theme.dart';

/// Một ghim trên [HeritageMap].
class MapPin {
  const MapPin({
    required this.id,
    required this.lat,
    required this.lng,
    required this.title,
    required this.color,
    this.label,
    this.sortKey = 0,
    this.imageUrl,
    this.scale = 1,
    this.onTap,
  });

  final String id;
  final double lat;
  final double lng;

  /// Tên ghim — trình đọc màn hình và bản thay thế trong `flutter test` dùng.
  final String title;
  final Color color;

  /// Chữ hiện ngay dưới ghim; `null` = không ghi (nhiều ghim sát nhau sẽ rối).
  final String? label;

  /// Lớn hơn thì nằm trên khi các ghim chồng nhau.
  final double sortKey;

  /// Có ảnh thì ghim là ảnh tròn viền [color] thay cho giọt nước. Ảnh chưa tải
  /// xong hoặc tải lỗi thì vẫn hiện giọt nước.
  final String? imageUrl;

  /// Phóng ghim (cả giọt nước, ảnh tròn lẫn chữ dưới ghim) — vẽ lại ở cỡ mới
  /// chứ không kéo giãn ảnh, nên không bị mờ.
  final double scale;
  final VoidCallback? onTap;

  String get _signature =>
      '$id|$lat|$lng|${color.toARGB32()}|$label|$sortKey|$imageUrl|$scale';
}

/// Khối (đa giác) trên mặt đất — vd. một khu vực admin vẽ trên bản đồ. Bấm
/// vào khối chạy [onTap]; [label] ghi ở giữa khối.
class MapBlock {
  const MapBlock({
    required this.id,
    required this.points,
    required this.label,
    required this.color,
    this.onTap,
  });

  final String id;

  /// Các đỉnh (lat, lng), không cần lặp đỉnh đầu ở cuối.
  final List<(double, double)> points;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  (double, double) get center => (
    points.map((p) => p.$1).reduce((a, b) => a + b) / points.length,
    points.map((p) => p.$2).reduce((a, b) => a + b) / points.length,
  );

  String get _signature => '$id|${points.join(',')}|$label|${color.toARGB32()}';
}

/// Vòng tròn theo mét trên mặt đất (vd. vùng beacon khách đang đứng).
class MapZone {
  const MapZone({
    required this.lat,
    required this.lng,
    required this.radiusMeters,
    required this.color,
  });

  final double lat;
  final double lng;
  final double radiusMeters;
  final Color color;

  String get _signature => '$lat|$lng|$radiusMeters|${color.toARGB32()}';
}

/// Điều khiển camera của [HeritageMap] từ màn cha (nút "Bạn đang ở…", FAB…).
class HeritageMapController {
  _HeritageMapState? _state;

  Future<void> moveTo(double lat, double lng, {double? zoom}) async =>
      _state?._moveTo(lat, lng, zoom: zoom);

  /// Đưa khung nhìn bao trọn [points]; một điểm thì zoom vào điểm đó.
  Future<void> fit(List<(double, double)> points) async => _state?._fit(points);
}

/// Bản đồ Mapbox (kiểu Standard, giống admin) dùng chung cho các màn bản đồ.
///
/// Gói phần lặp lại của mọi màn: ghim tô màu vẽ tại chỗ (không cần ảnh đóng
/// gói), vùng tròn theo mét, khoá camera trong Việt Nam, chừa chỗ cho thẻ phía
/// dưới, chấm vị trí của tôi. Thiếu token thì báo thay vì vẽ bản đồ trống;
/// trong `flutter test` (không có SDK native) thay bằng danh sách ghim bấm được.
class HeritageMap extends StatefulWidget {
  const HeritageMap({
    super.key,
    required this.pins,
    this.zone,
    this.blocks = const [],
    this.controller,
    this.initialFit = const [],
    this.singlePointZoom = 18,
    this.maxFitZoom = 19,
    this.padding = EdgeInsets.zero,
    this.showUserLocation = false,
    this.onMapTap,
    this.onUserMove,
  });

  final List<MapPin> pins;
  final MapZone? zone;
  final List<MapBlock> blocks;
  final HeritageMapController? controller;

  /// Các điểm cần thấy hết khi bản đồ vừa mở.
  final List<(double, double)> initialFit;

  /// Zoom khi [HeritageMapController.fit] chỉ có một điểm.
  final double singlePointZoom;

  /// Zoom tối đa khi ôm nhiều điểm sát nhau.
  final double maxFitZoom;

  /// Phần bản đồ bị thẻ/dải nổi che — logo Mapbox, la bàn và khung ôm điểm
  /// tránh ra.
  final EdgeInsets padding;
  final bool showUserLocation;

  /// Bấm vào chỗ trống trên bản đồ (không trúng ghim).
  final VoidCallback? onMapTap;

  /// Người dùng tự kéo/zoom bản đồ (gọi liên tục trong lúc kéo). Camera do
  /// app đổi ([HeritageMapController]) không tính — để màn cha biết khách đã
  /// rời khung ban đầu mà hiện nút "Xem tất cả".
  final VoidCallback? onUserMove;

  @override
  State<HeritageMap> createState() => _HeritageMapState();
}

class _HeritageMapState extends State<HeritageMap> {
  /// `flutter test` không có SDK Mapbox native.
  static final bool _inWidgetTest = Platform.environment.containsKey(
    'FLUTTER_TEST',
  );

  /// Giữa Việt Nam — khi chưa có điểm nào để ôm.
  static const _vietnam = (16.05, 106.5);

  MapboxMap? _map;
  PointAnnotationManager? _points;
  PolygonAnnotationManager? _zones;
  PolygonAnnotationManager? _blocks;
  PointAnnotationManager? _blockLabels;
  final _byBlockAnnotation = <String, MapBlock>{};
  String? _blocksSignature;

  /// Annotation id phía native → ghim, để tra lại khi bấm.
  final _byAnnotation = <String, MapPin>{};
  String? _pinsSignature;
  String? _zoneSignature;

  /// Đồng bộ ghim là chuỗi lệnh bất đồng bộ sang native; xếp hàng để hai lần
  /// rebuild liền nhau không xoá/tạo chéo nhau.
  Future<void> _sync = Future.value();

  /// Bấm ghim có thể kéo theo cả sự kiện bấm bản đồ — bỏ qua cái đó.
  DateTime _lastPinTap = DateTime(0);

  final _gestureSubs = <StreamSubscription<Object?>>[];

  final _pinImages = <String, Future<Uint8List>>{};
  double _dpr = 3;

  /// Ảnh của ghim ảnh theo URL: `null` = tải lỗi (dùng giọt nước mãi). Chưa có
  /// khoá = chưa tải xong — ghim tạm là giọt nước, tải xong thì vẽ lại.
  final _photos = <String, ui.Image?>{};
  final _photoLoads = <String>{};

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(HeritageMap old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      if (old.controller?._state == this) old.controller?._state = null;
      widget.controller?._state = this;
    }
    if (_map == null) return;
    _scheduleSync();
    if (old.padding != widget.padding) _applyOrnaments();
    if (old.showUserLocation != widget.showUserLocation) _applyLocation();
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller?._state = null;
    for (final sub in _gestureSubs) {
      sub.cancel();
    }
    for (final photo in _photos.values) {
      photo?.dispose();
    }
    super.dispose();
  }

  // ---- camera --------------------------------------------------------------

  Future<void> _moveTo(double lat, double lng, {double? zoom}) async {
    await _map?.easeTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: zoom,
      ),
      MapAnimationOptions(duration: 600),
    );
  }

  Future<void> _fit(
    List<(double, double)> points, {
    bool animate = true,
  }) async {
    final map = _map;
    if (map == null || points.isEmpty) return;
    if (points.length == 1) {
      final (lat, lng) = points.single;
      final camera = CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: widget.singlePointZoom,
      );
      animate
          ? await map.easeTo(camera, MapAnimationOptions(duration: 600))
          : await map.setCamera(camera);
      return;
    }
    final pad = widget.padding;
    final camera = await map.cameraForCoordinatesPadding(
      [for (final (lat, lng) in points) Point(coordinates: Position(lng, lat))],
      CameraOptions(pitch: 0, bearing: 0),
      // Chừa thêm chỗ cho đầu ghim (cao ~40) và nhãn dưới ghim.
      MbxEdgeInsets(
        top: 72 + pad.top,
        left: 48,
        bottom: 56 + pad.bottom,
        right: 48,
      ),
      widget.maxFitZoom,
      null,
    );
    animate
        ? await map.easeTo(camera, MapAnimationOptions(duration: 600))
        : await map.setCamera(camera);
  }

  // ---- tạo bản đồ ----------------------------------------------------------

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;
    // Điểm tham quan chỉ ở Việt Nam — giống admin, khoá camera để khỏi kéo lạc
    // sang nước khác. Khung rộng hơn đất liền để còn Hoàng Sa, Trường Sa.
    await map.setBounds(
      CameraBoundsOptions(
        bounds: CoordinateBounds(
          southwest: Point(coordinates: Position(101.0, 6.0)),
          northeast: Point(coordinates: Position(118.5, 24.0)),
          infiniteBounds: false,
        ),
        minZoom: 4,
        maxZoom: 20,
      ),
    );
    await map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    await _applyOrnaments();
    await _applyLocation();

    // Chỉ kéo và zoom: xoay/nghiêng không làm khuất điểm nào.
    for (final events in [
      map.gestures.pan.gestureEvents,
      map.gestures.zoom.gestureEvents,
    ]) {
      _gestureSubs.add(events.listen((_) => widget.onUserMove?.call()));
    }

    map.addInteraction(
      TapInteraction.onMap((_) {
        final sincePin = DateTime.now().difference(_lastPinTap);
        if (sincePin < const Duration(milliseconds: 400)) return;
        widget.onMapTap?.call();
      }),
    );

    // Thứ tự tạo = thứ tự lớp: khối dưới cùng, rồi vùng beacon, tên khối, ghim.
    _blocks = await map.annotations.createPolygonAnnotationManager();
    _blocks!.tapEvents(
      onTap: (annotation) {
        _lastPinTap = DateTime.now();
        _byBlockAnnotation[annotation.id]?.onTap?.call();
      },
    );
    _zones = await map.annotations.createPolygonAnnotationManager();
    _blockLabels = await map.annotations.createPointAnnotationManager();
    _points = await map.annotations.createPointAnnotationManager();
    _points!.tapEvents(
      onTap: (annotation) {
        _lastPinTap = DateTime.now();
        _byAnnotation[annotation.id]?.onTap?.call();
      },
    );
    if (!mounted) return;
    _scheduleSync();
    // Khung nhìn ban đầu đã đặt qua `viewport` (xem [_initialCamera]) — không
    // đặt thêm ở đây: hai lệnh camera chạy song song sang native, lệnh nào tới
    // sau thắng, nên bản đồ lúc ôm hết điểm lúc chỉ zoom vào một điểm.
  }

  /// Tắt mọi chữ và icon có sẵn của nền Mapbox — tên tỉnh/phường/sông, tên
  /// đường, quán xá, trạm xe, công trình nổi tiếng — để trên bản đồ chỉ còn
  /// ghim và tên của các điểm đã cấu hình ở admin (theo yêu cầu 2026-10-21;
  /// trước đó còn giữ tên đường/tên vùng để định hướng). Ghim của app là lớp
  /// annotation riêng nên không bị ảnh hưởng.
  ///
  /// Là cấu hình của style Standard nên phải đặt sau khi style tải xong, và
  /// đặt lại mỗi lần style tải lại.
  Future<void> _hideBasemapPlaces() async {
    final map = _map;
    if (map == null) return;
    // Từng thuộc tính một: bản SDK/style cũ thiếu thuộc tính nào (vd.
    // showLandmarkIcons) thì chỉ bỏ qua thuộc tính đó, các cái khác vẫn tắt.
    for (final property in const [
      'showPlaceLabels',
      'showRoadLabels',
      'showPointOfInterestLabels',
      'showTransitLabels',
      'showLandmarkIcons',
      'showLandmarkIconLabels',
    ]) {
      try {
        await map.setStyleImportConfigProperty('basemap', property, false);
      } catch (_) {
        // Style không phải Standard (không có import `basemap`) hoặc thuộc
        // tính không có — bản đồ vẫn dùng được, chỉ còn chữ của Mapbox.
      }
    }
  }

  /// Camera ban đầu, tính một lần theo cỡ khung bản đồ rồi giữ nguyên.
  ///
  /// Phải là cùng một giá trị qua mọi lần build: MapWidget đặt lại camera mỗi
  /// khi `viewport` đổi, nên tính lại (vd. khi [HeritageMap.padding] đổi lúc
  /// mở thẻ) sẽ kéo camera về chỗ cũ dù người dùng đã kéo đi.
  CameraViewportState? _initialViewport;

  CameraViewportState _initialCamera(ui.Size size) {
    final points = widget.initialFit;
    if (points.isEmpty) {
      return CameraViewportState(
        center: Point(coordinates: Position(_vietnam.$2, _vietnam.$1)),
        zoom: 4.5,
      );
    }
    if (points.length == 1) {
      final (lat, lng) = points.single;
      return CameraViewportState(
        center: Point(coordinates: Position(lng, lat)),
        zoom: widget.singlePointZoom,
      );
    }
    // Ôm khung theo phép chiếu Web Mercator của Mapbox (ô gạch 512 px ở zoom
    // 0), cùng lề như [_fit] — tự tính vì SDK chỉ tính được khi bản đồ đã tạo.
    double mercY(double lat) {
      final rad = lat * math.pi / 180;
      return (1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) / 2;
    }

    final xs = [for (final (_, lng) in points) (lng + 180) / 360];
    final ys = [for (final (lat, _) in points) mercY(lat)];
    final minX = xs.reduce(math.min), maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min), maxY = ys.reduce(math.max);
    final pad = widget.padding;
    final availW = math.max(size.width - 96, 1.0);
    final availH = math.max(size.height - 128 - pad.vertical, 1.0);
    final zoomX = maxX > minX
        ? math.log(availW / ((maxX - minX) * 512)) / math.ln2
        : widget.maxFitZoom;
    final zoomY = maxY > minY
        ? math.log(availH / ((maxY - minY) * 512)) / math.ln2
        : widget.maxFitZoom;
    final zoom = math.min(math.min(zoomX, zoomY), widget.maxFitZoom);

    final centerY = (minY + maxY) / 2;
    final centerLat =
        math.atan(_sinh(math.pi * (1 - 2 * centerY))) * 180 / math.pi;
    final centerLng = (minX + maxX) / 2 * 360 - 180;
    return CameraViewportState(
      center: Point(coordinates: Position(centerLng, centerLat)),
      zoom: zoom,
    );
  }

  static double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;

  Future<void> _applyOrnaments() async {
    final map = _map;
    if (map == null) return;
    final pad = widget.padding;
    await map.logo.updateSettings(LogoSettings(marginBottom: 8 + pad.bottom));
    await map.attribution.updateSettings(
      AttributionSettings(marginBottom: 8 + pad.bottom),
    );
    await map.compass.updateSettings(CompassSettings(marginTop: 8 + pad.top));
  }

  Future<void> _applyLocation() async {
    await _map?.location.updateSettings(
      LocationComponentSettings(
        enabled: widget.showUserLocation,
        pulsingEnabled: true,
      ),
    );
  }

  // ---- ghim & vùng ---------------------------------------------------------

  void _scheduleSync() {
    _sync = _sync.then((_) => _syncNow()).catchError((Object _) {
      // Bản đồ đã bị huỷ giữa chừng (rời màn) — lần sau tạo lại từ đầu.
    });
  }

  Future<void> _syncNow() async {
    final points = _points;
    final zones = _zones;
    if (!mounted || points == null || zones == null) return;

    final pins = widget.pins;
    final pinsSignature = pins.map((p) => p._signature).join(';');
    if (pinsSignature != _pinsSignature) {
      _pinsSignature = pinsSignature;
      // Mỗi màn chỉ vài chục ghim: xoá hết vẽ lại cho đơn giản, khỏi so từng cái.
      await points.deleteAll();
      _byAnnotation.clear();
      if (pins.isNotEmpty) {
        final options = [for (final pin in pins) await _pinOptions(pin)];
        final created = await points.createMulti(options);
        for (var i = 0; i < created.length && i < pins.length; i++) {
          final annotation = created[i];
          if (annotation != null) _byAnnotation[annotation.id] = pins[i];
        }
      }
    }

    await _syncBlocks();

    final zone = widget.zone;
    final zoneSignature = zone?._signature;
    if (zoneSignature != _zoneSignature) {
      _zoneSignature = zoneSignature;
      await zones.deleteAll();
      if (zone != null) {
        await zones.create(
          PolygonAnnotationOptions(
            geometry: Polygon(coordinates: [_circleRing(zone)]),
            fillColor: zone.color.withValues(alpha: 0.18).toARGB32(),
            fillOutlineColor: zone.color.toARGB32(),
          ),
        );
      }
    }
  }

  Future<void> _syncBlocks() async {
    final blocks = _blocks, labels = _blockLabels;
    if (blocks == null || labels == null) return;
    final list = widget.blocks;
    final signature = list.map((b) => b._signature).join(';');
    if (signature == _blocksSignature) return;
    _blocksSignature = signature;
    await blocks.deleteAll();
    await labels.deleteAll();
    _byBlockAnnotation.clear();
    if (list.isEmpty) return;
    final created = await blocks.createMulti([
      for (final block in list)
        PolygonAnnotationOptions(
          geometry: Polygon(
            coordinates: [
              [
                for (final (lat, lng) in [...block.points, block.points.first])
                  Position(lng, lat),
              ],
            ],
          ),
          fillColor: block.color.withValues(alpha: 0.32).toARGB32(),
          fillOutlineColor: block.color.toARGB32(),
        ),
    ]);
    for (var i = 0; i < created.length && i < list.length; i++) {
      final annotation = created[i];
      if (annotation != null) _byBlockAnnotation[annotation.id] = list[i];
    }
    // Tên khối: chỉ chữ (không ảnh), đặt ở trọng tâm các đỉnh.
    await labels.createMulti([
      for (final block in list)
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(block.center.$2, block.center.$1),
          ),
          textField: block.label,
          textSize: 13,
          textMaxWidth: 8,
          textColor: AppColors.primaryDark.toARGB32(),
          textHaloColor: Colors.white.toARGB32(),
          textHaloWidth: 1.6,
        ),
    ]);
  }

  Future<PointAnnotationOptions> _pinOptions(MapPin pin) async {
    final label = pin.label;
    final url = pin.imageUrl;
    final photo = url == null ? null : _photo(url);
    final color = pin.color.toARGB32();
    return PointAnnotationOptions(
      geometry: Point(coordinates: Position(pin.lng, pin.lat)),
      image: photo == null
          ? await _pinImage(pin.color, pin.scale)
          : await _photoPinImage(url!, photo, pin.color, pin.scale),
      // Ảnh trong style dùng chung theo id (cùng màu → một ảnh giọt nước); phía
      // native chỉ thêm ảnh khi id chưa có, nên id phải đổi khi nội dung đổi.
      iconImage: photo == null
          ? 'pin-$color-${pin.scale}'
          : 'photo-${url.hashCode}-$color-${pin.scale}',
      iconAnchor: IconAnchor.BOTTOM,
      symbolSortKey: pin.sortKey,
      textField: label,
      textAnchor: label == null ? null : TextAnchor.TOP,
      textOffset: label == null ? null : [0, 0.2],
      textSize: label == null ? null : 12.5 * math.sqrt(pin.scale),
      textMaxWidth: label == null ? null : 10,
      textColor: label == null ? null : AppColors.primaryDark.toARGB32(),
      textHaloColor: label == null ? null : Colors.white.toARGB32(),
      textHaloWidth: label == null ? null : 1.5,
    );
  }

  /// Vòng tròn bán kính tính bằng mét, xấp xỉ bằng đa giác 48 cạnh (Mapbox
  /// chỉ có vòng tròn theo pixel — đổi cỡ khi zoom).
  static List<Position> _circleRing(MapZone zone) {
    const steps = 48;
    const metersPerDegree = 111320.0;
    final dLat = zone.radiusMeters / metersPerDegree;
    final dLng =
        zone.radiusMeters /
        (metersPerDegree * math.cos(zone.lat * math.pi / 180));
    return [
      for (var i = 0; i <= steps; i++)
        Position(
          zone.lng + dLng * math.cos(2 * math.pi * i / steps),
          zone.lat + dLat * math.sin(2 * math.pi * i / steps),
        ),
    ];
  }

  /// Ảnh đã tải của [url], hoặc `null` (chưa xong/lỗi) và bắt đầu tải nếu chưa.
  ui.Image? _photo(String url) {
    if (_photos.containsKey(url)) return _photos[url];
    if (_photoLoads.add(url)) _loadPhoto(url);
    return null;
  }

  Future<void> _loadPhoto(String url) async {
    ui.Image? image;
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        // Giải mã nhỏ cỡ ghim (rộng 44 logic px): ảnh bìa gốc thường vài MB.
        final codec = await ui.instantiateImageCodec(
          res.bodyBytes,
          targetWidth: (44 * _dpr).round(),
        );
        image = (await codec.getNextFrame()).image;
      }
    } catch (_) {
      // Mất mạng / ảnh hỏng: giữ ghim giọt nước.
    }
    if (!mounted) {
      image?.dispose();
      return;
    }
    _photos[url] = image;
    if (image == null) return;
    // Buộc vẽ lại ghim: chữ ký ghim không đổi nhưng ảnh thì đã có.
    _pinsSignature = null;
    _scheduleSync();
  }

  Future<Uint8List> _photoPinImage(
    String url,
    ui.Image photo,
    Color color,
    double scale,
  ) => _pinImages['photo:$url|${color.toARGB32()}|$scale@$_dpr'] ??=
      _drawPhotoPin(photo, color, _dpr * scale);

  /// Ghim ảnh 52×62 (logic px, nhân thêm [MapPin.scale] qua [dpr]): ảnh tròn
  /// viền màu + viền trắng, mũi nhọn ở dưới chỉ đúng toạ độ.
  static Future<Uint8List> _drawPhotoPin(
    ui.Image photo,
    Color color,
    double dpr,
  ) async {
    const w = 52.0, h = 62.0, r = 25.0;
    const c = Offset(w / 2, r + 1);
    final ring = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final tip = Path()
      ..moveTo(c.dx - 8, c.dy + r - 3)
      ..lineTo(c.dx + 8, c.dy + r - 3)
      ..lineTo(w / 2, h - 1)
      ..close();
    final body = Path.combine(PathOperation.union, ring, tip);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    canvas.drawShadow(body, Colors.black, 3, false);
    canvas.drawPath(body, Paint()..color = color);
    canvas.drawCircle(c, r - 3, Paint()..color = Colors.white);

    // Cắt ảnh vừa khung tròn, kiểu "cover" (không méo).
    final inner = Rect.fromCircle(center: c, radius: r - 5);
    canvas.save();
    canvas.clipPath(Path()..addOval(inner));
    paintImage(
      canvas: canvas,
      rect: inner,
      image: photo,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
    );
    canvas.restore();

    final image = await recorder.endRecording().toImage(
      (w * dpr).ceil(),
      (h * dpr).ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }

  Future<Uint8List> _pinImage(Color color, double scale) =>
      _pinImages['${color.toARGB32()}|$scale@$_dpr'] ??= _drawPin(
        color,
        _dpr * scale,
      );

  /// Ghim giọt nước 30×40 (logic px), vẽ theo mật độ điểm ảnh của máy — iOS
  /// đọc ảnh theo scale màn hình nên ảnh vẽ ở 1x sẽ bị mờ.
  static Future<Uint8List> _drawPin(Color color, double dpr) async {
    const w = 30.0, h = 40.0, r = 13.0;
    const c = Offset(w / 2, r + 2);
    // Hai điểm tiếp giáp của mũi nhọn với vòng tròn, ở ngang dưới tâm 7px.
    final dx = math.sqrt(r * r - 49);
    final body = Path()
      ..moveTo(w / 2, h - 1)
      ..lineTo(c.dx - dx, c.dy + 7)
      ..arcToPoint(
        Offset(c.dx + dx, c.dy + 7),
        radius: const Radius.circular(r),
        largeArc: true,
      )
      ..close();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    canvas.drawShadow(body, Colors.black, 2, false);
    canvas.drawPath(body, Paint()..color = color);
    canvas.drawPath(
      body,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(c, 4.5, Paint()..color = Colors.white);

    final image = await recorder.endRecording().toImage(
      (w * dpr).ceil(),
      (h * dpr).ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }

  // ---- giao diện -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    _dpr = MediaQuery.devicePixelRatioOf(context);
    if (_inWidgetTest) {
      return _TestMapStub(pins: widget.pins, blocks: widget.blocks);
    }
    if (!MapboxConfig.isConfigured) {
      return MapMessage(
        icon: Icons.map_outlined,
        title: context.l10n.mapNotReadyTitle,
        text: context.l10n.mapNotReadyText,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => MapWidget(
        styleUri: MapboxStyles.STANDARD,
        viewport: _initialViewport ??= _initialCamera(constraints.biggest),
        onMapCreated: _onMapCreated,
        onStyleLoadedListener: (_) => _hideBasemapPlaces(),
      ),
    );
  }
}

/// Thông báo thay cho bản đồ (chưa có vị trí, chưa có token…).
class MapMessage extends StatelessWidget {
  const MapMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceTint,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thay Mapbox trong `flutter test`: mỗi ghim/khối là một nút bấm theo
/// [MapPin.title] / [MapBlock.label], bấm vào chạy đúng hành vi của nó.
class _TestMapStub extends StatelessWidget {
  const _TestMapStub({required this.pins, this.blocks = const []});

  final List<MapPin> pins;
  final List<MapBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceTint,
      child: ListView(
        padding: const EdgeInsets.only(top: 120, bottom: 200),
        children: [
          for (final block in blocks)
            TextButton(
              key: ValueKey(block.id),
              onPressed: block.onTap,
              child: Text(block.label),
            ),
          for (final pin in pins)
            TextButton(
              key: ValueKey(pin.id),
              onPressed: pin.onTap,
              child: Text(pin.title),
            ),
        ],
      ),
    );
  }
}

/// Nút tròn trắng nổi trên bản đồ (danh sách địa điểm, "Xem tất cả"…).
class MapIconButton extends StatelessWidget {
  const MapIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      // Có thể nằm cùng màn với FAB khác — tag mặc định trùng nhau sẽ lỗi Hero.
      heroTag: null,
      tooltip: tooltip,
      onPressed: onPressed,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primary,
      child: Icon(icon),
    );
  }
}

/// Nút đưa bản đồ về khung thấy hết các điểm, đặt cạnh bản đồ của các màn.
///
/// Màn cha chỉ hiện nút sau khi khách tự kéo/zoom ([HeritageMap.onUserMove])
/// hoặc app đã zoom sát vào một chỗ — đang ở khung ban đầu thì nút thừa.
class MapFitAllButton extends StatelessWidget {
  const MapFitAllButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => MapIconButton(
    icon: Icons.zoom_out_map,
    tooltip: context.l10n.seeAll,
    onPressed: onPressed,
  );
}
