import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rich_text_content.dart';

/// Trang chi tiết một bản tin.
///
/// Cùng bố cục với [ArtifactDetailScreen]: ảnh bìa co giãn theo cuộn, nút
/// back tròn nền mờ đè lên ảnh, nội dung chạy trên nền trắng bên dưới.
class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key, required this.item});

  final NewsItem item;

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
                  tooltip: 'Quay lại',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(item.imageAsset, fit: BoxFit.cover),
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
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 15, color: AppColors.textSecondary),
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
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Tóm tắt làm đoạn dẫn: chữ lớn hơn thân bài một chút và có
                  // vạch màu bên trái để tách khỏi phần nội dung.
                  Container(
                    padding: const EdgeInsets.only(left: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: AppColors.accent, width: 3),
                      ),
                    ),
                    child: Text(
                      item.summary,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  RichTextContent(html: item.body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
