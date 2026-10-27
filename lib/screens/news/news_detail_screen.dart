import 'package:flutter/material.dart';

import '../../data/news_repository.dart';
import '../../l10n/l10n.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rich_text_content.dart';

/// Trang chi tiết một bài viết.
///
/// Cùng bố cục với [ArtifactDetailScreen]: ảnh bìa co giãn theo cuộn, nút
/// back tròn nền mờ đè lên ảnh, nội dung chạy trên nền trắng bên dưới.
/// Tiêu đề, ngày, ảnh có sẵn từ danh sách nên hiện ngay; chỉ phần nội dung
/// phải tải thêm (`GET /blogs/:slug`).
class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key, required this.item});

  final NewsItem item;

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late Future<String> _body;

  NewsItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    _body = NewsRepository.instance.fetchBody(item);
  }

  void _retry() =>
      setState(() => _body = NewsRepository.instance.fetchBody(item));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            // Nút back mặc định là icon trần, đè lên ảnh sáng thì mất hút.
            // Bọc nền tròn mờ cho nó luôn đọc được.
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: Material(
                color: Colors.black.withValues(alpha: 0.32),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: context.l10n.back,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  NewsCover(item: item),
                  // Vệt tối ở đỉnh để nút back nổi trên ảnh sáng màu.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.4],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.dateLabel.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.dateLabel,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<String>(
                    future: _body,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }
                      if (snap.hasError) {
                        return _BodyError(
                          // 404: bài vừa bị gỡ hoặc chưa có bản thứ tiếng này.
                          message: switch (snap.error) {
                            ApiException(statusCode: 404) =>
                              context.l10n.newsUnavailable,
                            ApiException(:final message) => message,
                            _ => context.l10n.newsLoadFailed,
                          },
                          onRetry: _retry,
                        );
                      }
                      final html = snap.data ?? '';
                      if (html.isEmpty) {
                        return Text(
                          context.l10n.newsEmpty,
                          style: const TextStyle(color: AppColors.textSecondary),
                        );
                      }
                      return RichTextContent(html: html);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyError extends StatelessWidget {
  const _BodyError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: const TextStyle(
            fontSize: 14.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(context.l10n.retry),
        ),
      ],
    );
  }
}

/// Ảnh đại diện của bài viết. Bài chưa có ảnh hoặc ảnh tải lỗi (vd. file
/// trên server đã mất) thì vẽ nền màu thương hiệu kèm biểu tượng, để thẻ
/// không thành ô trống.
class NewsCover extends StatelessWidget {
  const NewsCover({super.key, required this.item, this.height});

  final NewsItem item;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final url = item.imageUrl;
    final placeholder = _placeholder();
    if (url == null) return placeholder;
    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }

  Widget _placeholder() => Container(
    height: height,
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.primaryDark],
      ),
    ),
    child: Icon(
      Icons.article_outlined,
      color: Colors.white.withValues(alpha: 0.7),
      size: 36,
    ),
  );
}
