import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartheritage/data/favorite_repository.dart';
import 'package:smartheritage/data/mock_data.dart';
import 'package:smartheritage/screens/favorites/favorites_screen.dart';
import 'package:smartheritage/services/api_client.dart';
import 'package:smartheritage/services/token_store.dart';
import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/theme/app_theme.dart';
import 'package:smartheritage/widgets/artifact_widgets.dart';

const _base = 'http://test.local/api/v1';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> _apiArtifact(String id) => {
      'id': id,
      'name': 'Trống đồng Đông Sơn',
      'era': 'Văn hoá Đông Sơn',
      'zone': 'Khu trưng bày A',
      'shortIntro': 'Tóm tắt.',
      'description': 'Mô tả.',
      'rating': 4.8,
      'reviewCount': 4,
      'audioDuration': '03:45',
      'videoDuration': '02:10',
    };

final _artifact = Artifact.fromJson(_apiArtifact('uuid-1'));

void _install(MockClient mock) {
  FavoriteRepository.instance =
      FavoriteRepository(api: ApiClient(httpClient: mock, baseUrl: _base));
}

Widget _harness(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TokenStore.instance.clear();
    // Yêu thích yêu cầu đăng nhập; không có phiên thì nút chỉ mở màn đăng nhập.
    AuthController.instance.setTestSession();
  });

  tearDown(() {
    AuthController.instance.resetForTest();
    FavoriteRepository.instance = FavoriteRepository();
  });

  testWidgets('bấm tim gọi PUT và đổi sang tim đặc', (tester) async {
    final calls = <String>[];
    _install(MockClient((req) async {
      calls.add('${req.method} ${req.url.path}');
      return _json({'favorite': true}, 201);
    }));
    await tester.pumpWidget(_harness(FavoriteButton(artifact: _artifact)));

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();

    expect(calls, ['PUT /api/v1/favorites/uuid-1']);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.text('Đã lưu vào danh sách yêu thích'), findsOneWidget);
  });

  testWidgets('lưu hỏng thì trả tim về rỗng và báo lỗi đỏ', (tester) async {
    _install(MockClient((_) async => _json({'message': 'lỗi'}, 500)));
    await tester.pumpWidget(_harness(FavoriteButton(artifact: _artifact)));

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();

    // Bản cũ báo "đã lưu" rồi để tim đỏ dù chẳng lưu ở đâu — giờ phải hoàn tác.
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.text('Đã lưu vào danh sách yêu thích'), findsNothing);
    expect(
      find.text('Không lưu được thay đổi, vui lòng thử lại.'),
      findsOneWidget,
    );
    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snack.backgroundColor, AppColors.danger);
  });

  testWidgets('bấm lần nữa thì gọi DELETE', (tester) async {
    final calls = <String>[];
    _install(MockClient((req) async {
      calls.add(req.method);
      if (req.method == 'PUT') return _json({'favorite': true}, 201);
      return http.Response('', 204);
    }));
    await tester.pumpWidget(_harness(FavoriteButton(artifact: _artifact)));

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();

    expect(calls, ['PUT', 'DELETE']);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.text('Đã xoá khỏi danh sách yêu thích'), findsOneWidget);
  });

  group('màn hình Yêu thích', () {
    testWidgets('hiện hiện vật server trả về', (tester) async {
      _install(MockClient((_) async => _json([_apiArtifact('uuid-1')])));
      await FavoriteRepository.instance.load();

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: const FavoritesScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Trống đồng Đông Sơn'), findsOneWidget);
      expect(find.text('Chưa có hiện vật yêu thích'), findsNothing);
    });

    testWidgets('chưa thích gì thì hiện trạng thái rỗng', (tester) async {
      _install(MockClient((_) async => _json([])));
      await FavoriteRepository.instance.load();

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: const FavoritesScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Chưa có hiện vật yêu thích'), findsOneWidget);
    });

    testWidgets('khách chưa đăng nhập thì mời đăng nhập', (tester) async {
      AuthController.instance.resetForTest();
      _install(MockClient((_) async => _json([])));

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: const FavoritesScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Đăng nhập để lưu yêu thích'), findsOneWidget);
    });
  });
}
