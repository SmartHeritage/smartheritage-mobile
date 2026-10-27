import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config.dart';
import '../l10n/l10n.dart';
import 'api_client.dart';

/// Lấy Firebase ID token qua đăng nhập Google, để đổi lấy phiên của
/// smartheritage-BE ở `POST /auth/google`.
///
/// Backend kiểm bằng `firebase-admin.verifyIdToken` — tức là token của
/// **Firebase**, không phải ID token Google — nên phải đăng nhập vào Firebase
/// bằng credential Google rồi mới xin token.
class GoogleAuth {
  static GoogleAuth instance = GoogleAuth();

  Future<void>? _ready;

  /// Khởi tạo Firebase + Google Sign-In lần đầu cần tới, không làm ở `main`:
  /// máy chưa có file cấu hình Firebase (google-services.json) vẫn mở app
  /// bình thường, chỉ nút Google báo lỗi.
  Future<void> _ensureReady() {
    return _ready ??=
        () async {
          if (Firebase.apps.isEmpty) await Firebase.initializeApp();
          await GoogleSignIn.instance.initialize(
            serverClientId: AppConfig.googleClientId,
          );
        }().catchError((Object e) {
          // Lỗi cấu hình thì lần bấm sau thử khởi tạo lại từ đầu.
          _ready = null;
          throw e;
        });
  }

  /// Mở màn chọn tài khoản Google. Trả về Firebase ID token, hoặc `null` khi
  /// người dùng tự huỷ (không phải lỗi, không cần báo gì).
  Future<String?> signIn() async {
    try {
      await _ensureReady();
      final account = await GoogleSignIn.instance.authenticate();
      final googleIdToken = account.authentication.idToken;
      if (googleIdToken == null) {
        throw ApiException(appStrings.googleSignInFailed);
      }
      final result = await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: googleIdToken),
      );
      final token = await result.user?.getIdToken();
      if (token == null) throw ApiException(appStrings.googleSignInFailed);
      return token;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      debugPrint('Google sign-in: ${e.code} ${e.description}');
      throw ApiException(appStrings.googleSignInFailed);
    } on FirebaseException catch (e) {
      // Gồm cả lỗi thiếu cấu hình Firebase (chưa có google-services.json /
      // GoogleService-Info.plist) lẫn lỗi của FirebaseAuth.
      debugPrint('Firebase: ${e.code} ${e.message}');
      throw ApiException(appStrings.googleSignInFailed);
    } on ApiException {
      rethrow;
    } on Exception catch (e) {
      // PlatformException của plugin native (vd. Android thiếu cấu hình).
      debugPrint('Google sign-in: $e');
      throw ApiException(appStrings.googleSignInFailed);
    }
  }

  /// Gọi khi đăng xuất khỏi app: quên tài khoản Google vừa chọn để lần sau
  /// được chọn lại, không tự rơi vào tài khoản cũ.
  ///
  /// Chỉ làm khi đã khởi tạo trong lần chạy này (tức là vừa dùng Google) —
  /// không bắt người chưa từng bấm nút Google phải khởi tạo Firebase.
  Future<void> signOut() async {
    if (_ready == null) return;
    try {
      await _ready;
      await Future.wait([
        GoogleSignIn.instance.signOut(),
        FirebaseAuth.instance.signOut(),
      ]);
    } catch (e) {
      // Phiên của app đã xoá rồi; còn sót trạng thái Google thì chỉ là lần
      // sau không hiện màn chọn tài khoản.
      debugPrint('Google sign-out: $e');
    }
  }
}
