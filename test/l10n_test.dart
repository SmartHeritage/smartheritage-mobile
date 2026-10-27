import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartheritage/data/artifact_repository.dart';
import 'package:smartheritage/data/favorite_repository.dart';
import 'package:smartheritage/data/news_repository.dart';
import 'package:smartheritage/l10n/l10n.dart';
import 'package:smartheritage/screens/home/home_screen_v2.dart';
import 'package:smartheritage/screens/profile/language_screen.dart';
import 'package:smartheritage/services/api_client.dart';
import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/state/language_state.dart';
import 'package:smartheritage/theme/app_theme.dart';

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

/// Dựng app giống `SmartHeritageApp`: ngôn ngữ giao diện theo LanguageController.
Widget _app(Widget home) => ListenableBuilder(
  listenable: LanguageController.instance,
  builder: (context, _) => MaterialApp(
    theme: AppTheme.light,
    locale: LanguageController.instance.uiLocale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  final language = LanguageController.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'visitor.language': 'vi'});
    // Backend giả: có một hiện vật với nội dung vi/en/ja → màn ngôn ngữ có ja.
    final api = ApiClient(
      baseUrl: 'http://test.local/api/v1',
      httpClient: MockClient((req) async {
        if (req.url.path.endsWith('/artifacts')) {
          return _json([
            {
              'id': 'a1',
              'name': 'Trống đồng',
              'language': {
                'available': ['vi', 'en', 'ja'],
              },
            },
          ]);
        }
        if (req.url.path.endsWith('/blogs')) return _json({'items': []});
        return _json([]);
      }),
    );
    FavoriteRepository.instance = FavoriteRepository(api: api);
    AuthController.instance = AuthController(api: api);
    final repo = ArtifactRepository(api: api);
    await repo.refresh();
    language.repositoryForTest = repo;
    language.newsForTest = NewsRepository(api: api)..setItemsForTest(const []);
    await language.load();
  });

  test('mọi khoá trong bản tiếng Việt đều có bản tiếng Anh', () {
    Map<String, dynamic> read(String f) =>
        jsonDecode(File('lib/l10n/$f').readAsStringSync())
            as Map<String, dynamic>;
    final vi = read('app_vi.arb').keys.where((k) => !k.startsWith('@'));
    final en = read('app_en.arb');
    final missing = vi.where((k) => !en.containsKey(k)).toList();
    expect(missing, isEmpty);
  });

  test('ngôn ngữ chưa dịch giao diện thì giao diện là tiếng Anh', () async {
    expect(language.uiLocale, const Locale('vi'));
    await language.select('en');
    expect(language.uiLocale, const Locale('en'));
    expect(language.hasUiTranslation, isTrue);

    await language.select('ja');
    // Nội dung vẫn xin backend bằng ja, chỉ giao diện rơi về tiếng Anh.
    expect(language.code, 'ja');
    expect(language.uiLocale, const Locale('en'));
    expect(language.hasUiTranslation, isFalse);
  });

  testWidgets('chọn English thì chữ trên trang chủ đổi sang tiếng Anh', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const Scaffold(body: HomeScreenV2())));
    await tester.pump();
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Lịch sử'), findsOneWidget);

    await tester.runAsync(() => language.select('en'));
    await tester.pump();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Lịch sử'), findsNothing);
    // Nút ngôn ngữ ở góc hiện đúng thứ tiếng đang chọn.
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('chọn ngôn ngữ chưa dịch giao diện thì báo và dùng tiếng Anh', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LanguageScreen()),
                ),
                child: const Text('MỞ'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('MỞ'));
    await tester.pumpAndSettle();

    // Danh sách chỉ ghi tên ngôn ngữ, không còn dòng chú thích bên dưới;
    // việc giao diện sẽ là tiếng Anh được báo sau khi xác nhận (bên dưới).
    expect(find.textContaining('Giao diện chưa có bản dịch'), findsNothing);

    await tester.tap(find.text('日本語'));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('Xác nhận'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(language.uiLocale, const Locale('en'));
    expect(find.textContaining("isn't available in 日本語 yet"), findsOneWidget);
  });
}
