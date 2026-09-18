import 'package:flutter/material.dart';

import '../../data/favorite_repository.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artifact_widgets.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hiện vật yêu thích')),
      body: ListenableBuilder(
        listenable: AuthController.instance,
        builder: (context, _) {
          if (!AuthController.instance.isLoggedIn) {
            return _LoginPrompt(
              icon: Icons.favorite_border,
              title: 'Đăng nhập để lưu yêu thích',
              message:
                  'Đăng nhập để lưu và đồng bộ các hiện vật\nyêu thích của bạn trên mọi thiết bị',
            );
          }
          return _buildList();
        },
      ),
    );
  }

  Widget _buildList() {
    final store = FavoriteRepository.instance;
    return ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          // Lấy thẳng danh sách server trả về, không lọc từ danh sách hiện vật
          // đang hiển thị — yêu thích có thể trỏ tới hiện vật không nằm trong
          // trang hiện tại.
          final favorites = store.artifacts;
          if (store.isLoading && favorites.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border,
                        size: 44, color: AppColors.accent),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Chưa có hiện vật yêu thích',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Nhấn ♥ trên hiện vật để lưu lại\nvà xem lại bất cứ lúc nào',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            itemCount: favorites.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                ArtifactListTile(artifact: favorites[i]),
          );
        },
    );
  }
}

/// Trạng thái mời đăng nhập cho các tính năng lưu dữ liệu.
class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.surfaceTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppColors.accent),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => AuthController.ensureLoggedIn(context),
                icon: const Icon(Icons.login, size: 20),
                label: const Text('Đăng nhập / Đăng ký'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
