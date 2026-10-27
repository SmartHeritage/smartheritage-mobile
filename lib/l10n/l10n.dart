import 'package:flutter/widgets.dart';

import '../state/language_state.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

/// Chữ giao diện theo ngôn ngữ khách chọn: `context.l10n.homeTitle`.
///
/// Sửa chữ ở `lib/l10n/app_vi.arb` (bản gốc) và `app_en.arb`; lớp
/// [AppLocalizations] tự sinh lại khi `flutter pub get` / `flutter run`.
extension L10nContext on BuildContext {
  /// Widget dựng ngoài MaterialApp của app (vd. widget test) không có bản dịch
  /// nào được nạp — khi đó dùng tiếng Việt, đúng chữ gốc của app.
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('vi'));
}

/// Cho chỗ không có BuildContext (controller, repository, thông báo lỗi): theo
/// ngôn ngữ giao diện hiện tại. Trong widget thì dùng `context.l10n` để đổi ngôn
/// ngữ là widget tự dựng lại.
AppLocalizations get appStrings =>
    lookupAppLocalizations(LanguageController.instance.uiLocale);

/// Tên ngôn ngữ [code] viết bằng ngôn ngữ giao diện hiện tại (vd. giao diện tiếng
/// Việt: `ja` → "Tiếng Nhật"). Mã chưa có tên dịch thì trả tên gốc.
String languageName(AppLocalizations l10n, String code) => switch (code) {
  'vi' => l10n.langNameVi,
  'en' => l10n.langNameEn,
  'fr' => l10n.langNameFr,
  'ja' => l10n.langNameJa,
  'ko' => l10n.langNameKo,
  'zh' => l10n.langNameZh,
  _ => LanguageController.nativeName(code),
};
