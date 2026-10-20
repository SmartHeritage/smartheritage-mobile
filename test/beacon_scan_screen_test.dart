import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/screens/scan/beacon_scan_screen.dart';
import 'package:smartheritage/state/beacon_scan_state.dart';

void main() {
  final scan = BeaconScanController.instance;

  setUp(scan.stopScan);
  tearDown(scan.stopScan);

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
