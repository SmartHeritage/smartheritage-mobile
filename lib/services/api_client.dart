import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'token_store.dart';

/// Lỗi trả về từ backend hoặc lỗi mạng, đã gói thành thông điệp tiếng Việt
/// đủ để hiển thị thẳng cho người dùng.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.isNetwork = false});

  final String message;
  final int? statusCode;

  /// `true` khi không gọi tới được server (mất mạng, server chưa bật, timeout).
  /// Bên gọi dùng cờ này để quyết định có rơi về dữ liệu mock hay không.
  final bool isNetwork;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// HTTP client cho smartheritage-BE: gắn bearer token, tự làm mới khi 401,
/// và quy mọi lỗi về [ApiException].
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? '';

  static final ApiClient instance = ApiClient();

  final http.Client _http;
  final String _baseUrl;

  String get baseUrl => _baseUrl.isEmpty ? AppConfig.apiBaseUrl : _baseUrl;

  /// Gọi khi refresh token cũng hỏng — phiên coi như chết, bên trên phải
  /// đưa người dùng về trạng thái khách.
  void Function()? onSessionExpired;

  /// Chặn hai request 401 cùng lúc kích hoạt hai lần refresh: request thứ hai
  /// chờ đúng cái refresh đang chạy.
  Future<bool>? _refreshing;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path, {Object? body}) =>
      _send('DELETE', path, body: body);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool allowRefresh = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: query?.isEmpty ?? true ? null : query,
    );

    final request = http.Request(method, uri)
      ..headers['accept'] = 'application/json';
    final token = TokenStore.instance.accessToken;
    if (token != null) request.headers['authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    http.Response response;
    try {
      final streamed = await _http
          .send(request)
          .timeout(AppConfig.requestTimeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException('Máy chủ phản hồi quá lâu.', isNetwork: true);
    } on SocketException {
      throw ApiException('Không kết nối được máy chủ.', isNetwork: true);
    } on http.ClientException {
      throw ApiException('Không kết nối được máy chủ.', isNetwork: true);
    }

    // 401 kèm refresh token còn sống → làm mới rồi gửi lại đúng một lần.
    // allowRefresh=false ở lần thứ hai để 401 tiếp theo không thành vòng lặp.
    if (response.statusCode == 401 &&
        allowRefresh &&
        TokenStore.instance.hasSession) {
      if (await _refreshSession()) {
        return _send(method, path, query: query, body: body,
            allowRefresh: false);
      }
    }

    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final body = response.body;
    final status = response.statusCode;

    if (status == 204 || body.isEmpty) {
      if (status >= 400) throw ApiException(_genericError(status), statusCode: status);
      return null;
    }

    dynamic parsed;
    try {
      parsed = jsonDecode(body);
    } on FormatException {
      // Sai baseUrl hay đụng proxy thì server trả HTML — đừng ném lỗi parse
      // khó hiểu ra màn hình.
      throw ApiException(_genericError(status), statusCode: status);
    }

    if (status >= 400) {
      final message = parsed is Map && parsed['message'] is String
          ? parsed['message'] as String
          : _genericError(status);
      throw ApiException(message, statusCode: status);
    }
    return parsed;
  }

  String _genericError(int status) => switch (status) {
        400 => 'Dữ liệu gửi lên không hợp lệ.',
        401 => 'Phiên đăng nhập đã hết hạn.',
        403 => 'Bạn không có quyền thực hiện thao tác này.',
        404 => 'Không tìm thấy dữ liệu.',
        _ => 'Máy chủ gặp sự cố ($status).',
      };

  Future<bool> _refreshSession() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final refreshToken = TokenStore.instance.refreshToken;
    if (refreshToken == null) return false;
    try {
      // Không đi qua _send: request này phải là ẩn danh và không được phép
      // tự gọi refresh lần nữa.
      final response = await _http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: const {
              'content-type': 'application/json',
              'accept': 'application/json',
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(AppConfig.requestTimeout);
      if (response.statusCode >= 400) {
        await TokenStore.instance.clear();
        onSessionExpired?.call();
        return false;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await TokenStore.instance.save(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      // Lỗi mạng thì giữ nguyên token — lần sau còn thử lại được.
      return false;
    }
  }
}
