import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartheritage/data/artifact_repository.dart';
import 'package:smartheritage/data/favorite_repository.dart';
import 'package:smartheritage/services/api_client.dart';
import 'package:smartheritage/state/auth_state.dart';
import 'package:smartheritage/state/language_state.dart';

const _base = 'http://test.local/api/v1';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  final language = LanguageController.instance;
  late List<String> calls;
  late List<Map<String, dynamic>> patches;
  late AuthController auth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'visitor.language': 'vi'});
    calls = [];
    patches = [];
    final api = ApiClient(
      baseUrl: _base,
      httpClient: MockClient((req) async {
        calls.add('${req.method} ${req.url.path}?${req.url.query}');
        if (req.method == 'PATCH') {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          patches.add(body);
          return _json({
            'id': 'u1',
            'email': 'khach@example.com',
            'preferredLanguage': body['preferredLanguage'],
          });
        }
        return _json([]);
      }),
    );
    FavoriteRepository.instance = FavoriteRepository(api: api);
    auth = AuthController(api: api);
    AuthController.instance = auth;
    language.repositoryForTest = ArtifactRepository(api: api);
    await language.load();
  });

  test('khách: đổi ngôn ngữ thì tải lại hiện vật kèm ?language=, không PATCH',
      () async {
    final ok = await language.select('en');

    expect(ok, isTrue);
    expect(language.code, 'en');
    expect(calls, contains('GET /api/v1/artifacts?language=en'));
    expect(patches, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('visitor.language'), 'en');
  });

  test('đã đăng nhập: ghi thêm preferredLanguage vào tài khoản', () async {
    auth.setTestSession();

    final ok = await language.select('en');

    expect(ok, isTrue);
    expect(patches.single, {'preferredLanguage': 'en'});
  });

  test('chưa biết backend có gì thì cho chọn vi/en', () {
    expect(language.choices, ['vi', 'en']);
  });
}
