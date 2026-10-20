import 'package:flutter/material.dart';

import 'data/artifact_repository.dart';
import 'data/news_repository.dart';
import 'screens/splash_screen.dart';
import 'services/mapbox_config.dart';
import 'state/auth_state.dart';
import 'state/language_state.dart';
import 'state/visit_history_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MapboxConfig.init();
  VisitHistoryController.instance.load();
  _bootstrap();
  runApp(const SmartHeritageApp());
}

/// Khôi phục phiên và nạp dữ liệu thật ngay trong lúc splash đang chạy, nên
/// không chờ ở đây: màn hình đầu tiên đã có sẵn dữ liệu mock để vẽ.
///
/// Khôi phục phiên trước để request hiện vật đi kèm bearer token, và nạp
/// ngôn ngữ đã chọn để nội dung về đúng thứ tiếng ngay lần tải đầu.
Future<void> _bootstrap() async {
  await AuthController.instance.restoreSession();
  await LanguageController.instance.load();
  // Tin tức độc lập với hiện vật — tải song song, hỏng bên nào không kéo
  // bên kia.
  await Future.wait([
    ArtifactRepository.instance.ensureLoaded(),
    NewsRepository.instance.ensureLoaded(),
  ]);
}

class SmartHeritageApp extends StatelessWidget {
  const SmartHeritageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Heritage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
