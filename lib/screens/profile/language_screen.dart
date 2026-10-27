import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../state/language_state.dart';
import '../../theme/app_theme.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = LanguageController.instance.code;
  bool _saving = false;

  /// Lấy theo những ngôn ngữ backend thực sự có nội dung (`language.available`
  /// của hiện vật); chưa biết thì dùng hai thứ tiếng app có sẵn.
  ///
  /// Mỗi dòng chỉ có cờ + tên gốc của ngôn ngữ (2026-10-21 bỏ dòng chú thích
  /// bên dưới theo yêu cầu). Chọn thứ tiếng chưa có bản dịch giao diện thì vẫn
  /// được báo sau khi xác nhận (`langUiFallbackNotice`).
  List<(String, String, String)> get _languages => [
        for (final code in LanguageController.instance.choices)
          (
            code,
            LanguageController.labels[code]?.$1 ?? '🌐',
            LanguageController.nativeName(code),
          ),
      ];

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final savedToAccount = await LanguageController.instance.select(_selected);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    // Giao diện vừa đổi ngôn ngữ → lấy chữ theo ngôn ngữ MỚI (appStrings), không
    // theo context của màn sắp đóng.
    final l10n = appStrings;
    final language = LanguageController.instance;
    if (!language.hasUiTranslation) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.langUiFallbackNotice(
          LanguageController.nativeName(language.code),
        )),
        duration: const Duration(seconds: 6),
      ));
    } else {
      messenger.showSnackBar(savedToAccount
          ? SnackBar(content: Text(l10n.langUpdated))
          : errorSnackBar(l10n.langSavedLocalOnly));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.langScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.translate, color: AppColors.accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.langScreenIntro,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryLight,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final (code, flag, name) in _languages)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _selected = code),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _selected == code
                        ? AppColors.surfaceTint
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selected == code
                          ? AppColors.primary
                          : AppColors.divider,
                      width: _selected == code ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(flag, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (_selected == code)
                        const Icon(Icons.check_circle,
                            color: AppColors.primary)
                      else
                        const Icon(Icons.circle_outlined,
                            color: AppColors.divider),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _confirm,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : Text(context.l10n.confirm),
          ),
        ],
      ),
    );
  }
}
