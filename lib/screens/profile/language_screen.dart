import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'vi';

  static const _languages = [
    ('vi', '🇻🇳', 'Tiếng Việt', 'Vietnamese'),
    ('en', '🇬🇧', 'English', 'Tiếng Anh'),
    ('fr', '🇫🇷', 'Français', 'Tiếng Pháp'),
    ('ja', '🇯🇵', '日本語', 'Tiếng Nhật'),
    ('ko', '🇰🇷', '한국어', 'Tiếng Hàn'),
    ('zh', '🇨🇳', '中文', 'Tiếng Trung'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn ngôn ngữ')),
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
              children: const [
                Icon(Icons.translate, color: AppColors.accent, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nội dung giới thiệu, thuyết minh âm thanh và phụ đề video sẽ hiển thị theo ngôn ngữ bạn chọn.',
                    style: TextStyle(
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
          for (final (code, flag, name, sub) in _languages)
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sub,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
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
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Đã cập nhật ngôn ngữ hiển thị'),
              ));
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}
