import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../data/review_repository.dart';
import '../../services/api_client.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artifact_widgets.dart';

/// Đánh giá và gửi phản hồi về hiện vật hoặc khu di tích, dạng màn hình riêng.
///
/// Trang chi tiết hiện vật dùng [FeedbackForm] trực tiếp làm một tab.
class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key, this.artifact});

  /// Nếu null: phản hồi chung về khu di tích.
  final Artifact? artifact;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá & phản hồi')),
      body: FeedbackForm(
        artifact: artifact,
        onSubmitted: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// Form đánh giá, không bọc Scaffold — nhúng được vào tab hoặc màn hình riêng.
class FeedbackForm extends StatefulWidget {
  const FeedbackForm({
    super.key,
    this.artifact,
    this.onSubmitted,
    this.onSubmittedInPlace,
    this.scrollable = true,
  });

  /// Nếu null: phản hồi chung về khu di tích.
  final Artifact? artifact;

  /// Gọi sau khi gửi thành công. Dạng màn hình riêng thì pop; để null (dạng
  /// tab) thì form tự xoá để gửi tiếp được.
  final VoidCallback? onSubmitted;

  /// Gọi sau khi gửi thành công ở dạng tab — để tab nạp lại danh sách và thấy
  /// đánh giá vừa gửi.
  final VoidCallback? onSubmittedInPlace;

  /// Tự cuộn hay không. Đặt `false` khi form nằm sẵn trong một danh sách cuộn
  /// khác — hai scrollable lồng nhau làm ensureVisible cuộn qua lại không dừng.
  final bool scrollable;

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  int _rating = 0;
  bool _busy = false;
  final Set<String> _tags = {};
  final _controller = TextEditingController();

  /// Mã tag lấy từ [reviewTagLabels] — gửi mã lên server, hiện nhãn cho khách.
  static final _tagOptions = reviewTagLabels.keys.toList();

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

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(errorSnackBar('Vui lòng chọn số sao đánh giá'));
      return;
    }
    // POST /reviews yêu cầu đăng nhập — đánh giá gắn với tài khoản.
    if (!await AuthController.ensureLoggedIn(context)) return;
    if (!mounted) return;

    setState(() => _busy = true);
    // Lấy messenger trước khi pop — sau khi pop thì context không còn dùng được.
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ReviewRepository.instance.submit(
        artifactId: widget.artifact?.id,
        rating: _rating,
        tags: _tags.toList(),
        comment: _controller.text,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(errorSnackBar(e.message));
      return;
    }

    if (!mounted) return;
    setState(() => _busy = false);
    widget.onSubmitted?.call();
    if (widget.onSubmitted == null) {
      setState(() {
        _rating = 0;
        _tags.clear();
        _controller.clear();
      });
      widget.onSubmittedInPlace?.call();
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Cảm ơn bạn! Phản hồi đã được gửi thành công.'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final artifact = widget.artifact;
    const padding = EdgeInsets.fromLTRB(24, 16, 24, 32);
    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (artifact != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(10),
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
                      color:
                          i <= _rating ? AppColors.warning : AppColors.divider,
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
                  label: Text(reviewTagLabels[tag]!),
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
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 20),
            label: const Text('Gửi phản hồi'),
          ),
        ],
      );

    if (!widget.scrollable) return Padding(padding: padding, child: content);
    return SingleChildScrollView(padding: padding, child: content);
  }
}

/// Tab "Đánh giá" ở trang chi tiết: danh sách đánh giá đã duyệt, rồi tới form.
///
/// Tự nạp lại sau khi gửi — `POST /reviews` mặc định vào thẳng trạng thái
/// `approved` nên đánh giá vừa gửi phải thấy được ngay.
class ArtifactReviewsTab extends StatefulWidget {
  const ArtifactReviewsTab({super.key, required this.artifact});

  final Artifact artifact;

  @override
  State<ArtifactReviewsTab> createState() => _ArtifactReviewsTabState();
}

class _ArtifactReviewsTabState extends State<ArtifactReviewsTab> {
  late Future<List<Review>> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = _load();
  }

  Future<List<Review>> _load() =>
      ReviewRepository.instance.listForArtifact(widget.artifact.id);

  void _reload() {
    // Không đặt _load() thẳng trong setState: closure dạng mũi tên trả về
    // chính Future đó, và Flutter coi setState trả Future là lỗi.
    final future = _load();
    setState(() {
      _reviews = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView + Column chứ không phải ListView: tab này nằm trong
    // NestedScrollView của trang chi tiết, và ListView ở đó làm ensureVisible
    // cuộn qua lại không bao giờ dừng.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        FutureBuilder<List<Review>>(
          future: _reviews,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            // Lỗi mạng: không chặn đường gửi đánh giá mới, chỉ nói là chưa
            // tải được phần đã có.
            if (snapshot.hasError) {
              return _notice(
                'Chưa tải được danh sách đánh giá.',
                onRetry: _reload,
              );
            }
            final reviews = snapshot.data ?? const <Review>[];
            if (reviews.isEmpty) {
              return _notice('Chưa có đánh giá nào. Hãy là người đầu tiên!');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text(
                    'Đánh giá của khách tham quan (${reviews.length})',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                for (final review in reviews) _ReviewCard(review: review),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.divider),
              ],
            );
          },
        ),
        FeedbackForm(
          artifact: widget.artifact,
          // Đã nằm trong ListView của tab rồi, không tự cuộn nữa.
          scrollable: false,
          // Dạng tab thì form tự xoá; nạp lại để thấy đánh giá vừa gửi.
          onSubmittedInPlace: _reload,
        ),
        ],
      ),
    );
  }

  Widget _notice(String message, {VoidCallback? onRetry}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= review.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 18,
                  color: AppColors.warning,
                ),
              const Spacer(),
              if (review.createdAt != null)
                Text(
                  _dateLabel(review.createdAt!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          if (review.tagLabels.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final label in review.tagLabels)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceTint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if ((review.comment ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!.trim(),
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _dateLabel(DateTime d) {
    final local = d.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    return '$dd/$mm/${local.year}';
  }
}
