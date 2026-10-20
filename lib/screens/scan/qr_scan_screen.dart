import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/artifact_repository.dart';
import '../../data/mock_data.dart';
import '../../services/qr_code.dart';
import '../../state/visit_history_state.dart';
import '../../theme/app_theme.dart';
import '../artifact/artifact_detail_screen.dart';

/// Quét mã QR đặt cạnh hiện vật → mở thẳng trang hiện vật đó.
///
/// Mã phải chứa id hiện vật (xem [artifactIdCandidates]). Mã lạ thì báo và
/// quét tiếp, không đóng màn. Lượt quét ghi vào lịch sử trên máy; backend chỉ
/// nhận lượt ghé qua beacon (`POST /scans` bắt buộc thông tin beacon), nên tài
/// khoản đăng nhập không lưu lượt này lên server.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  /// Đã khớp một hiện vật, đang chuyển màn — bỏ qua các khung hình sau.
  bool _handled = false;

  /// Mã lạ vừa báo — camera đọc cùng một mã nhiều lần mỗi giây, báo một lần.
  String? _lastUnknown;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Artifact? _match(String raw) {
    final repo = ArtifactRepository.instance;
    for (final id in artifactIdCandidates(raw)) {
      final artifact = repo.tryById(id);
      if (artifact != null) return artifact;
    }
    return null;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final artifact = _match(raw);
      if (artifact != null) {
        _open(artifact);
        return;
      }
      if (raw != _lastUnknown) {
        _lastUnknown = raw;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            errorSnackBar(
              'Mã QR này không phải mã hiện vật của SmartHeritage.',
            ),
          );
      }
    }
  }

  Future<void> _open(Artifact artifact) async {
    _handled = true;
    await _controller.stop();
    VisitHistoryController.instance.recordBeaconVisit(artifact);
    if (!mounted) return;
    // Thay màn quét: bấm back từ trang hiện vật về thẳng nơi đã mở máy quét.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ArtifactDetailScreen(artifact: artifact),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Quét mã QR'),
        actions: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, _) => IconButton(
              tooltip: 'Đèn pin',
              onPressed: state.torchState == TorchState.unavailable
                  ? null
                  : _controller.toggleTorch,
              icon: Icon(
                state.torchState == TorchState.on
                    ? Icons.flash_on
                    : Icons.flash_off,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _CameraError(error: error),
          ),
          const _ScanFrame(),
        ],
      ),
    );
  }
}

/// Khung ngắm ở giữa + lời hướng dẫn.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Đưa mã QR trên bảng giới thiệu hiện vật vào khung',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                size: 48,
                color: Colors.white70,
              ),
              const SizedBox(height: 12),
              Text(
                denied
                    ? 'Ứng dụng chưa được dùng camera. Hãy bật quyền Camera '
                          'cho SmartHeritage trong Cài đặt của máy.'
                    : 'Không mở được camera. Thử đóng màn này rồi mở lại.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
