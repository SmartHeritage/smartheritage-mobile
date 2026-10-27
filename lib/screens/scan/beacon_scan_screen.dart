import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../state/beacon_scan_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/beacon_scan_toggle.dart';

/// Trang quét beacon: một nút Bluetooth to ở giữa, đang quét thì có sóng lan
/// ra. Mở trang là tự bật quét; bấm nút để bật/tắt.
///
/// Trang này không tự hiện popup: popup "phát hiện hiện vật" vẫn do trang chủ
/// (luôn sống trong IndexedStack của MainShell) nghe [BeaconScanController] và
/// mở bằng navigator gốc, nên nó hiện đè lên trang này như mọi nơi khác. Rời
/// trang thì vẫn quét tiếp — giống công tắc quét ở các chỗ khác.
class BeaconScanScreen extends StatefulWidget {
  const BeaconScanScreen({super.key, this.autoStart = true});

  /// Mở trang là bật quét luôn (khách đã chọn "Quét beacon" thì đừng bắt bấm
  /// thêm lần nữa). Test tắt đi để tự điều khiển.
  final bool autoStart;

  @override
  State<BeaconScanScreen> createState() => _BeaconScanScreenState();
}

class _BeaconScanScreenState extends State<BeaconScanScreen>
    with SingleTickerProviderStateMixin {
  final _scan = BeaconScanController.instance;
  late final AnimationController _waves = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    _scan.addListener(_syncWaves);
    _syncWaves();
    if (widget.autoStart && !_scan.isScanning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_scan.isScanning) toggleBeaconScan(context);
      });
    }
  }

  @override
  void dispose() {
    _scan.removeListener(_syncWaves);
    _waves.dispose();
    super.dispose();
  }

  /// Sóng chỉ chạy khi đang quét — tắt quét thì dừng hẳn, không tốn khung hình.
  void _syncWaves() {
    if (_scan.isScanning) {
      if (!_waves.isAnimating) _waves.repeat();
    } else {
      _waves.stop();
      _waves.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.scanBeaconTitle)),
      body: ListenableBuilder(
        listenable: _scan,
        builder: (context, _) {
          final scanning = _scan.isScanning;
          final zone = _scan.currentZone;
          final error = _scan.startError;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  _PulseButton(
                    waves: _waves,
                    active: scanning,
                    onTap: () => toggleBeaconScan(context),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    scanning
                        ? (zone == null
                              ? context.l10n.beaconSearching
                              : context.l10n.mapYouAreInZone(
                                  zone.name ?? 'beacon',
                                ))
                        : context.l10n.beaconTapToStart,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    error ??
                        (scanning
                            ? context.l10n.beaconScanningHint
                            : context.l10n.beaconIdleHint),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: error == null
                          ? AppColors.textSecondary
                          : AppColors.danger,
                    ),
                  ),
                  const Spacer(flex: 3),
                  if (scanning)
                    TextButton.icon(
                      onPressed: () => toggleBeaconScan(context),
                      icon: const Icon(Icons.bluetooth_disabled),
                      label: Text(context.l10n.beaconStop),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Nút Bluetooth tròn to; [active] thì có ba vòng sóng lan ra lệch pha nhau.
class _PulseButton extends StatelessWidget {
  const _PulseButton({
    required this.waves,
    required this.active,
    required this.onTap,
  });

  final Animation<double> waves;
  final bool active;
  final VoidCallback onTap;

  static const double _size = 150;

  /// Khung vẽ sóng — sóng lan ra tới gần gấp đôi cỡ nút.
  static const double _area = 290;

  @override
  Widget build(BuildContext context) {
    // Người dùng tắt chuyển động trong cài đặt máy: giữ một vòng tĩnh để vẫn
    // biết là đang quét.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: _area,
      height: _area,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (active)
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: waves,
                builder: (context, _) => CustomPaint(
                  size: const Size.square(_area),
                  painter: _WavePainter(
                    progress: reduceMotion ? 0.35 : waves.value,
                    count: reduceMotion ? 1 : 3,
                  ),
                ),
              ),
            ),
          Semantics(
            button: true,
            label: active
                ? context.l10n.beaconTurnOff
                : context.l10n.beaconTurnOn,
            excludeSemantics: true,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: active
                      ? const [AppColors.primaryLight, AppColors.primaryDark]
                      : [Colors.grey.shade400, Colors.grey.shade600],
                ),
                border: Border.all(color: Colors.white, width: 6),
                boxShadow: [
                  BoxShadow(
                    color: (active ? AppColors.primaryDark : Colors.black)
                        .withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: onTap,
                    child: Center(
                      child: Icon(
                        active ? Icons.bluetooth_searching : Icons.bluetooth,
                        size: 68,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Các vòng sóng đồng tâm: mỗi vòng lớn dần từ mép nút ra ngoài và mờ dần.
class _WavePainter extends CustomPainter {
  _WavePainter({required this.progress, required this.count});

  /// 0..1, lặp lại.
  final double progress;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const start = _PulseButton._size / 2;
    final end = size.shortestSide / 2;
    for (var i = 0; i < count; i++) {
      final t = (progress + i / count) % 1;
      final radius = start + (end - start) * Curves.easeOut.transform(t);
      final opacity = (1 - t) * 0.45;
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = AppColors.primary.withValues(alpha: opacity * 0.5),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppColors.primary.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress || old.count != count;
}
