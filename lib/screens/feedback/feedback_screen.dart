import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artifact_widgets.dart';

/// Đánh giá và gửi phản hồi về hiện vật hoặc khu di tích.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key, this.artifact});

  /// Nếu null: phản hồi chung về khu di tích.
  final Artifact? artifact;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 0;
  final Set<String> _tags = {};
  final _controller = TextEditingController();

  static const _tagOptions = [
    'Nội dung hấp dẫn',
    'Thuyết minh rõ ràng',
    'Dễ tìm vị trí',
    'Hình ảnh đẹp',
    'Cần thêm ngôn ngữ',
    'Âm thanh chưa tốt',
  ];

  static const _ratingLabels = [
    '',
    'Rất tệ',
    'Chưa hài lòng',
    'Bình thường',
    'Hài lòng',
    'Tuyệt vời',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng chọn số sao đánh giá'),
      ));
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Cảm ơn bạn! Phản hồi đã được gửi thành công.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final artifact = widget.artifact;
    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá & phản hồi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (artifact != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ArtifactThumb(artifact: artifact, size: 52, radius: 12),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artifact.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            artifact.zone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text(
                'Trải nghiệm tham quan của bạn hôm nay thế nào?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  GestureDetector(
                    onTap: () => setState(() => _rating = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        i <= _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 44,
                        color: i <= _rating
                            ? AppColors.warning
                            : AppColors.divider,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _ratingLabels[_rating],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Điều gì khiến bạn ấn tượng?',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final tag in _tagOptions)
                  FilterChip(
                    label: Text(tag),
                    selected: _tags.contains(tag),
                    onSelected: (selected) => setState(() {
                      selected ? _tags.add(tag) : _tags.remove(tag);
                    }),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _tags.contains(tag)
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                    checkmarkColor: Colors.white,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Chia sẻ thêm với chúng tôi',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText:
                    'Cảm nhận, góp ý của bạn giúp chúng tôi phục vụ tốt hơn...',
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_a_photo_outlined, size: 20),
              label: const Text('Đính kèm hình ảnh'),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send_rounded, size: 20),
              label: const Text('Gửi phản hồi'),
            ),
          ],
        ),
      ),
    );
  }
}
