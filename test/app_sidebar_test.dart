import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/app_info.dart';
import 'package:smartheritage/screens/home/home_screen.dart';
import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/state/beacon_scan_state.dart';
import 'package:smartheritage/widgets/app_sidebar.dart';

/// Mô phỏng đúng cách lồng ở [MainShell]: sidebar gắn trên Scaffold ngoài,
/// HomeScreen là body và không có Scaffold riêng.
Widget _harness() {
  return const MaterialApp(
    home: Scaffold(
      drawer: AppSidebar(),
      body: HomeScreen(),
    ),
  );
}

void main() {
  tearDown(() {
    BeaconScanController.instance.stopScan();
    AuthController.instance.resetForTest();
  });

  testWidgets('nút menu ở header trang chủ mở được sidebar', (tester) async {
    await tester.pumpWidget(_harness());

    expect(find.text('Lịch sử tham quan'), findsNothing);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Quét iBeacon'), findsOneWidget);
    expect(find.text('Lịch sử tham quan'), findsOneWidget);
    expect(find.text('Ngôn ngữ'), findsOneWidget);
    expect(find.text('Câu hỏi thường gặp'), findsOneWidget);
    // Chưa đăng nhập → hiện chip đăng nhập, không hiện đăng xuất.
    expect(find.text('Đăng nhập / Đăng ký'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsNothing);
  });

  testWidgets('công tắc quét chỉ còn ở sidebar, không ở trang khám phá',
      (tester) async {
    await tester.pumpWidget(_harness());

    // Card quét iBeacon đã bỏ khỏi trang khám phá.
    expect(find.text('Quét iBeacon đang tắt'), findsNothing);
    expect(find.text('Đang quét iBeacon'), findsNothing);
    expect(find.byType(SwitchListTile), findsNothing);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Đang tắt'), findsOneWidget);

    await tester.tap(find.byType(SwitchListTile));
    // Không pumpAndSettle: quá 4s thì beacon mock phát hiện hiện vật rồi mở
    // sheet — ngoài phạm vi test này.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(BeaconScanController.instance.isScanning, isTrue);
    expect(find.text('Đang tìm hiện vật ở gần bạn…'), findsOneWidget);
    expect(find.text('Đang tắt'), findsNothing);

    // Dừng trước khi framework soát timer pending.
    BeaconScanController.instance.stopScan();
    await tester.pump();
  });

  testWidgets('đã đăng nhập thì sidebar hiện tên, email và đăng xuất',
      (tester) async {
    AuthController.instance.setTestSession();
    await tester.pumpWidget(_harness());

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Lê Nhật Anh'), findsOneWidget);
    expect(find.text('lenhatanh2411@gmail.com'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);
    expect(find.text('Đăng nhập / Đăng ký'), findsNothing);
    // Phiên bản nằm bên phải nút đăng xuất.
    expect(find.text(AppInfo.versionLabel), findsOneWidget);
  });

  testWidgets('mục câu hỏi thường gặp mở trang trợ giúp', (tester) async {
    await tester.pumpWidget(_harness());

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Câu hỏi thường gặp'));
    await tester.pumpAndSettle();

    expect(find.text('Trợ giúp & FAQ'), findsOneWidget);
    expect(find.text('iBeacon & phát hiện hiện vật'), findsOneWidget);
  });

  testWidgets('khách chưa đăng nhập thì không có hàng đăng xuất/phiên bản',
      (tester) async {
    await tester.pumpWidget(_harness());

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Đăng xuất'), findsNothing);
    expect(find.text(AppInfo.versionLabel), findsNothing);
  });
}
