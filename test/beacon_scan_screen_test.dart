import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/screens/auth/login_screen.dart';
import 'package:smartheritage/screens/scan/beacon_scan_screen.dart';
import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/state/beacon_scan_state.dart';
import 'package:smartheritage/widgets/scan_choice_sheet.dart';

void main() {
  final scan = BeaconScanController.instance;

  setUp(() {
    scan.stopScan();
    // Bật quét phải đăng nhập; trường hợp khách có test riêng ngay dưới.
    AuthController.instance.setTestSession();
  });
  tearDown(() {
    scan.stopScan();
    AuthController.instance.resetForTest();
  });

  testWidgets('khách bật quét thì phải đăng nhập, chưa quét gì', (
    tester,
  ) async {
    AuthController.instance.resetForTest();
    await tester.pumpWidget(
      const MaterialApp(home: BeaconScanScreen(autoStart: false)),
    );
    await tester.tap(find.bySemanticsLabel('Bật quét beacon'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(scan.isScanning, isFalse);
  });

  testWidgets('khách bấm nút quét thì phải đăng nhập, không mở bảng chọn', (
    tester,
  ) async {
    AuthController.instance.resetForTest();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showScanChoiceSheet(context),
            child: const Text('QUÉT'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('QUÉT'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Quét mã QR'), findsNothing);
  });

  testWidgets('nút Bluetooth giữa trang bật/tắt quét', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BeaconScanScreen(autoStart: false)),
    );
    expect(find.text('Chạm để bắt đầu quét'), findsOneWidget);
    expect(find.byIcon(Icons.bluetooth), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Bật quét beacon'));
    // Sóng chạy lặp mãi nên không pumpAndSettle được.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(scan.isScanning, isTrue);
    expect(find.text('Đang dò beacon quanh bạn…'), findsOneWidget);
    expect(find.byIcon(Icons.bluetooth_searching), findsOneWidget);

    await tester.tap(find.text('Tắt quét'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(scan.isScanning, isFalse);
    expect(find.text('Chạm để bắt đầu quét'), findsOneWidget);
  });

  testWidgets('mở trang là tự bật quét', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BeaconScanScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(scan.isScanning, isTrue);
    scan.stopScan();
    await tester.pump(const Duration(milliseconds: 300));
  });
}
