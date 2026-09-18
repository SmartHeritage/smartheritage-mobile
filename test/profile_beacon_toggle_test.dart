import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/screens/profile/profile_screen.dart';
import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/state/beacon_scan_state.dart';
import 'package:smartheritage/theme/app_theme.dart';

Widget _harness() {
  return MaterialApp(
    theme: AppTheme.light,
    home: const ProfileScreen(),
  );
}

/// Mục quét iBeacon nằm dưới màn hình test 800x600 nên phải kéo tới nơi.
Future<void> _scrollToBeaconItem(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Quét iBeacon'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.text('Quét iBeacon'));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    BeaconScanController.instance.stopScan();
    AuthController.instance.resetForTest();
  });

  testWidgets('trang cá nhân có mục quét iBeacon, mặc định tắt',
      (tester) async {
    await tester.pumpWidget(_harness());
    await _scrollToBeaconItem(tester);

    expect(find.text('Thiết bị'), findsOneWidget);
    expect(find.text('Quét iBeacon'), findsOneWidget);
    expect(find.text('Đang tắt'), findsOneWidget);
    expect(find.byIcon(Icons.bluetooth_disabled), findsOneWidget);
  });

  testWidgets('bấm vào hàng thì bật quét và đổi nhãn', (tester) async {
    await tester.pumpWidget(_harness());
    await _scrollToBeaconItem(tester);

    await tester.tap(find.text('Quét iBeacon'));
    // Không pumpAndSettle: quá 4s thì beacon mock phát hiện hiện vật.
    await tester.pump();

    expect(BeaconScanController.instance.isScanning, isTrue);
    expect(find.text('Đang quét'), findsOneWidget);
    expect(find.text('Đang tắt'), findsNothing);
    expect(find.byIcon(Icons.bluetooth_searching), findsOneWidget);

    // Dừng trước khi framework soát timer pending.
    BeaconScanController.instance.stopScan();
    await tester.pump();
  });

  testWidgets('công tắc phản ánh state bật sẵn từ nơi khác', (tester) async {
    // Bật từ sidebar/trang chủ trước khi mở trang cá nhân.
    BeaconScanController.instance.startScan();
    await tester.pumpWidget(_harness());
    await _scrollToBeaconItem(tester);

    // Trang còn một Switch khác (Thông báo) nên phải bám theo đúng hàng.
    final beaconSwitch = tester.widget<Switch>(
      find.descendant(
        of: find
            .ancestor(
              of: find.text('Quét iBeacon'),
              matching: find.byType(Row),
            )
            .first,
        matching: find.byType(Switch),
      ),
    );
    expect(beaconSwitch.value, isTrue);
    expect(find.text('Đang quét'), findsOneWidget);

    BeaconScanController.instance.stopScan();
    await tester.pump();
  });
}
