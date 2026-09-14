import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/screens/artifact/artifact_detail_screen.dart';
import 'package:smartheritage/screens/audio/audio_player_screen.dart';
import 'package:smartheritage/state/audio_player_state.dart';
import 'package:smartheritage/widgets/mini_player_bar.dart';

/// Dựng trang chi tiết cùng mini-player, giống bố cục thật ở [MainShell] —
/// mini-player phải có trong cây để tái hiện lỗi notify giữa lúc build.
Widget _harness(Artifact artifact, {int initialTabIndex = 0}) {
  return MaterialApp(
    home: Scaffold(
      body: ArtifactDetailScreen(
        artifact: artifact,
        initialTabIndex: initialTabIndex,
      ),
      bottomNavigationBar: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [MiniPlayerBar()],
      ),
    ),
  );
}

void main() {
  // Kích thước logic của iPhone 17 Pro — nơi hàng era + zone từng tràn 3.6px.
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  tearDown(() => AudioPlayerController.instance.close());

  testWidgets('hàng era + zone không tràn ở khổ máy hẹp', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_harness(MockData.artifacts.first));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('mở màn nghe thuyết minh không markNeedsBuild giữa lúc build',
      (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // AudioPlayerScreen gọi play() trong initState; mini-player phải có trong
    // cây để tái hiện lỗi notify giữa lúc build.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AudioPlayerScreen(artifact: MockData.artifacts.first),
        bottomNavigationBar: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [MiniPlayerBar()],
        ),
      ),
    ));
    // Không dùng pumpAndSettle: ticker của audio là Timer.periodic, không đứng.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);
    expect(AudioPlayerController.instance.artifact?.id,
        MockData.artifacts.first.id);

    // Dừng ticker ngay trong test body, trước khi framework soát timer pending.
    AudioPlayerController.instance.close();
    await tester.pump();
  });

  testWidgets('tab Giới thiệu không còn nút đánh giá', (tester) async {
    await tester.pumpWidget(_harness(MockData.artifacts.first));
    await tester.pump();

    expect(find.text('Đánh giá & gửi phản hồi'), findsNothing);
    // Nhãn tab đã có, nhưng form chỉ build khi mở tab.
    expect(find.text('Đánh giá'), findsOneWidget);
    expect(find.text('Gửi phản hồi'), findsNothing);
  });

  testWidgets('tab Đánh giá hiện form phản hồi của hiện vật', (tester) async {
    await tester.pumpWidget(
      _harness(MockData.artifacts.first, initialTabIndex: 3),
    );
    await tester.pumpAndSettle();

    expect(find.text('Điều gì khiến bạn ấn tượng?'), findsOneWidget);
    expect(find.text('Gửi phản hồi'), findsOneWidget);
  });

  testWidgets('gửi phản hồi ở dạng tab thì không pop trang chi tiết',
      (tester) async {
    await tester.pumpWidget(
      _harness(MockData.artifacts.first, initialTabIndex: 3),
    );
    await tester.pumpAndSettle();

    // Form dài hơn viewport → phải cuộn tới trước khi tap, không thì tap trượt.
    // Và không pumpAndSettle khi chờ SnackBar: nó chờ luôn tới lúc SnackBar tự
    // tắt, khi đó không còn tìm thấy nữa.
    await tester.ensureVisible(find.text('Gửi phản hồi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi phản hồi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.text('Vui lòng chọn số sao đánh giá'), findsOneWidget);

    // Cho SnackBar này hết hạn 4s rồi tắt — ScaffoldMessenger xếp hàng, nếu còn
    // hiện thì SnackBar sau không lên. pumpAndSettle không đủ: 4s là Timer,
    // không phải animation nên nó trả về ngay khi SnackBar vẫn đang hiện.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng chọn số sao đánh giá'), findsNothing);

    // Chọn 5 sao rồi gửi.
    await tester.ensureVisible(find.byIcon(Icons.star_outline_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_outline_rounded).last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gửi phản hồi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi phản hồi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.text('Cảm ơn bạn! Phản hồi đã được gửi thành công.'),
        findsOneWidget);
    // Vẫn ở trang chi tiết, và form đã xoá để gửi tiếp được — dùng nhãn số sao
    // thay vì đếm icon star_rounded, vì title block cũng có một icon như vậy.
    expect(find.text('Điều gì khiến bạn ấn tượng?'), findsOneWidget);
    expect(find.text('Tuyệt vời'), findsNothing);
  });
}
