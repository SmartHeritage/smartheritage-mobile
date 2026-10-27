import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:smartheritage/data/artifact_repository.dart';
import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/screens/audio/audio_player_screen.dart';
import 'package:smartheritage/screens/auth/login_screen.dart';
import 'package:smartheritage/screens/main_shell.dart';
import 'package:smartheritage/screens/playlist/playlist_screen.dart';
import 'package:smartheritage/services/api_client.dart';
import 'package:smartheritage/state/audio_player_state.dart';
import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/state/beacon_scan_state.dart';
import 'package:smartheritage/widgets/mini_player_bar.dart';

import 'support/fake_audio_player.dart';

const _base = 'http://test.local/api/v1';

String _url(String id) => 'http://test.local/uploads/$id.mp3';

Map<String, dynamic> _artifact(String id, {bool audio = true}) => {
  'id': id,
  'name': 'Hiện vật $id',
  'audioDuration': '01:00',
  if (audio) 'audioUrl': _url(id),
};

/// a2 chưa có bản thu: không được lọt vào danh sách lẫn hàng đợi.
final _artifacts = [
  _artifact('a1'),
  _artifact('a2', audio: false),
  _artifact('a3'),
  _artifact('a4'),
];

Future<http.Response> _backend(http.Request req) async {
  final body = req.url.path.endsWith('/artifacts') ? _artifacts : const [];
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    200,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

ArtifactRepository _repo() => ArtifactRepository(
  api: ApiClient(httpClient: MockClient(_backend), baseUrl: _base),
);

void main() {
  late FakeAudioPlayer player;
  late AudioPlayerController audio;

  setUp(() {
    player = FakeAudioPlayer();
    audio = AudioPlayerController(player: player);
    AudioPlayerController.instance = audio;
  });

  group('hàng đợi của AudioPlayerController', () {
    late List<Artifact> tracks;

    setUp(() async {
      final repo = _repo();
      await repo.refresh();
      tracks = repo.artifacts;
    });

    test(
      'bỏ bài câm, hết bài tự sang bài kế, hết danh sách thì dừng',
      () async {
        await audio.playQueue(tracks, 0);
        expect(audio.queue.map((a) => a.id), ['a1', 'a3', 'a4']);
        expect(player.lastUrl, _url('a1'));

        player.emitCompleted();
        await pumpEventQueue();
        expect(audio.artifact?.id, 'a3');
        expect(player.lastUrl, _url('a3'));

        player.emitCompleted();
        await pumpEventQueue();
        expect(audio.artifact?.id, 'a4');
        expect(audio.hasNext, isFalse);

        player.emitCompleted();
        await pumpEventQueue();
        expect(audio.artifact?.id, 'a4');
        expect(audio.isPlaying, isFalse);
        expect(audio.position, Duration.zero);
      },
    );

    test(
      'lùi: đã nghe quá 3 giây thì về đầu bài, chưa thì về bài trước',
      () async {
        await audio.playQueue(tracks, 2); // a3
        player.emitPosition(const Duration(seconds: 10));
        await audio.previous();
        expect(audio.artifact?.id, 'a3');
        expect(audio.position, Duration.zero);

        await audio.previous();
        expect(audio.artifact?.id, 'a1');
      },
    );

    test(
      'mở một hiện vật ngoài danh sách thì thôi nghe theo danh sách',
      () async {
        await audio.playQueue(tracks, 0);
        final outsider = Artifact.fromJson({
          ..._artifact('x9'),
          'name': 'Hiện vật ngoài',
        });
        await audio.play(outsider);
        expect(audio.queue, isEmpty);

        player.emitCompleted();
        await pumpEventQueue();
        // Không nhảy về danh sách cũ.
        expect(audio.artifact?.id, 'x9');
      },
    );
  });

  group('PlaylistScreen', () {
    late ArtifactRepository original;

    setUp(() {
      original = ArtifactRepository.instance;
      ArtifactRepository.instance = _repo();
      AuthController.instance.setTestSession();
    });

    tearDown(() {
      ArtifactRepository.instance = original;
      AuthController.instance.resetForTest();
    });

    Future<void> open(WidgetTester tester) async {
      await tester.runAsync(ArtifactRepository.instance.refresh);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlaylistScreen(),
            bottomNavigationBar: MiniPlayerBar(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('chỉ liệt kê hiện vật có thuyết minh', (tester) async {
      await open(tester);
      expect(find.text('3 bản thuyết minh'), findsOneWidget);
      expect(find.text('Hiện vật a1'), findsOneWidget);
      expect(find.text('Hiện vật a2'), findsNothing);
    });

    testWidgets('khách xem được danh sách, bấm nghe thì phải đăng nhập', (
      tester,
    ) async {
      AuthController.instance.resetForTest();
      await open(tester);
      expect(find.text('Hiện vật a1'), findsOneWidget);

      await tester.tap(find.text('Phát tất cả'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(player.lastUrl, isNull);
    });

    testWidgets(
      'Phát tất cả phát từ bài đầu, bấm một bài thì nhảy tới bài đó',
      (tester) async {
        await open(tester);

        await tester.tap(find.text('Phát tất cả'));
        await tester.pumpAndSettle();
        expect(player.lastUrl, _url('a1'));
        expect(audio.queue, hasLength(3));

        await tester.tap(find.text('Hiện vật a4'));
        await tester.pumpAndSettle();
        expect(player.lastUrl, _url('a4'));
        // Vẫn nghe theo danh sách, không thành bài lẻ.
        expect(audio.queue, hasLength(3));
      },
    );

    testWidgets('mini-player có nút bài kế khi còn bài phía sau', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('Hiện vật a3'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Bài tiếp theo'));
      await tester.pumpAndSettle();
      expect(audio.artifact?.id, 'a4');
      // a4 là bài cuối: hết "bài kế" thì nút biến mất.
      expect(find.byTooltip('Bài tiếp theo'), findsNothing);
    });

    testWidgets('màn nghe đang mở thì đi theo khi danh sách tự sang bài', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('Phát tất cả'));
      await tester.pumpAndSettle();

      final first = audio.artifact!;
      await tester.tap(find.byType(MiniPlayerBar));
      await tester.pumpAndSettle();
      expect(find.byType(AudioPlayerScreen), findsOneWidget);
      expect(find.text(first.name), findsWidgets);

      // Controller dựng trong setUp (ngoài vùng fake-async) nên việc nạp bài
      // kế chạy trên vòng sự kiện thật.
      await tester.runAsync(() async {
        player.emitCompleted();
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();
      // Tên bài kế hiện trên màn nghe (và mini-player phía sau).
      expect(
        find.descendant(
          of: find.byType(AudioPlayerScreen),
          matching: find.text('Hiện vật a3'),
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('đăng xuất thì tắt thuyết minh đang phát', (tester) async {
    final auth = AuthController.instance;
    auth.setTestSession();
    addTearDown(auth.resetForTest);
    final repo = _repo();
    await tester.runAsync(repo.refresh);

    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.runAsync(() => audio.playQueue(repo.artifacts, 0));
    await tester.pump();
    expect(audio.artifact?.id, 'a1');

    auth.resetForTest();
    await tester.pump();
    expect(audio.artifact, isNull);
    expect(audio.queue, isEmpty);
    expect(audio.isPlaying, isFalse);

    BeaconScanController.instance.stopScan();
  });
}
