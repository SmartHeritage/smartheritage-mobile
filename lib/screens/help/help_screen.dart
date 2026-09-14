import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_info.dart';
import '../../theme/app_theme.dart';
import '../feedback/feedback_screen.dart';

/// Trợ giúp & câu hỏi thường gặp.
///
/// Nội dung viết theo hành vi thật của app: công tắc quét nằm ở sidebar,
/// thuyết minh tự phát khi beacon phát hiện, khách không cần đăng nhập...
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  // Thay bằng thông tin liên hệ thật của khu di tích trước khi phát hành.
  static const _supportEmail = 'hotro@smartheritage.vn';
  static const _supportPhone = '1900 0000';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trợ giúp & FAQ')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          for (final group in _groups) ...[
            _GroupCard(group: group),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 4),
          _contactCard(context),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'Smart Heritage ${AppInfo.versionLabel}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vẫn chưa tìm được câu trả lời?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Liên hệ ban quản lý khu di tích, hoặc gửi phản hồi trực tiếp '
            'trong ứng dụng.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _contactRow(
            context,
            icon: Icons.mail_outline,
            label: _supportEmail,
            copiedMessage: 'Đã sao chép email hỗ trợ',
          ),
          const SizedBox(height: 10),
          _contactRow(
            context,
            icon: Icons.phone_outlined,
            label: _supportPhone,
            copiedMessage: 'Đã sao chép số hỗ trợ',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FeedbackScreen()),
              ),
              icon: const Icon(Icons.rate_review_outlined, size: 20),
              label: const Text('Gửi phản hồi'),
            ),
          ),
        ],
      ),
    );
  }

  /// Bấm để sao chép — app chưa có url_launcher nên không mở được app mail/gọi.
  Widget _contactRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String copiedMessage,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        await Clipboard.setData(ClipboardData(text: label));
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(copiedMessage)));
      },
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Icon(Icons.copy_rounded,
              size: 15, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final _FaqGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
            color: AppColors.surfaceTint,
            child: Row(
              children: [
                Icon(group.icon, size: 19, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < group.items.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 16, endIndent: 16),
            _FaqRow(item: group.items[i]),
          ],
        ],
      ),
    );
  }
}

class _FaqRow extends StatelessWidget {
  const _FaqRow({required this.item});

  final _FaqItem item;

  @override
  Widget build(BuildContext context) {
    // Bỏ divider mặc định của ExpansionTile để dùng divider của _GroupCard.
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        title: Text(
          item.question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.35,
          ),
        ),
        children: [
          Text(
            item.answer,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem(this.question, this.answer);

  final String question;
  final String answer;
}

class _FaqGroup {
  const _FaqGroup({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<_FaqItem> items;
}

const _groups = <_FaqGroup>[
  _FaqGroup(
    title: 'iBeacon & phát hiện hiện vật',
    icon: Icons.bluetooth_searching,
    items: [
      _FaqItem(
        'iBeacon là gì và app dùng nó để làm gì?',
        'Mỗi khu trưng bày được gắn một thiết bị iBeacon phát sóng Bluetooth '
            'tầm ngắn. Khi bạn đi tới gần, ứng dụng nhận được sóng và tự nhận '
            'ra bạn đang ở cạnh hiện vật nào, rồi mở phần giới thiệu tương '
            'ứng. Bạn không phải quét mã hay nhập số hiệu hiện vật.',
      ),
      _FaqItem(
        'Bật tính năng quét ở đâu?',
        'Mở sidebar bằng nút menu ở góc trên bên trái trang Khám phá, rồi bật '
            'công tắc "Quét iBeacon". Công tắc này áp dụng cho toàn ứng dụng, '
            'tắt lúc nào cũng được.',
      ),
      _FaqItem(
        'Vì sao app không phát hiện được hiện vật nào?',
        'Hãy kiểm tra theo thứ tự: đã bật công tắc "Quét iBeacon" trong '
            'sidebar chưa, Bluetooth của máy đã mở chưa, và ứng dụng đã được '
            'cấp quyền Bluetooth trong phần cài đặt của hệ điều hành chưa. '
            'Sóng iBeacon chỉ phủ vài mét, nên bạn cũng cần đứng gần khu trưng '
            'bày.',
      ),
      _FaqItem(
        'Quét iBeacon có tốn pin nhiều không?',
        'iBeacon dùng Bluetooth Low Energy, tiêu thụ pin rất thấp so với GPS '
            'hay 4G. Dù vậy, nếu bạn đã tham quan xong thì nên tắt công tắc '
            'trong sidebar để tiết kiệm thêm.',
      ),
    ],
  ),
  _FaqGroup(
    title: 'Thuyết minh âm thanh',
    icon: Icons.headphones_rounded,
    items: [
      _FaqItem(
        'Thuyết minh có tự phát không?',
        'Có. Khi iBeacon phát hiện bạn ở gần một hiện vật, ứng dụng tự mở và '
            'phát thuyết minh của hiện vật đó, bạn không cần bấm gì. Nếu muốn '
            'nghe lại hoặc nghe hiện vật khác, vào trang chi tiết hiện vật và '
            'bấm "Nghe thuyết minh âm thanh" ở cuối tab Giới thiệu.',
      ),
      _FaqItem(
        'Làm sao tắt tiếng khi đang ở nơi cần yên lặng?',
        'Bấm nút hình loa. Nút này có ở ba nơi: thanh phát nhỏ phía dưới màn '
            'hình, khung thông báo khi beacon phát hiện hiện vật, và trang '
            'nghe thuyết minh. Tắt tiếng chỉ làm im âm thanh, phần thuyết minh '
            'vẫn chạy và bạn vẫn đọc được nội dung chữ.',
      ),
      _FaqItem(
        'Đổi tốc độ đọc được không?',
        'Được. Ở trang nghe thuyết minh, bấm nút tốc độ bên phải hàng điều '
            'khiển để chuyển lần lượt qua 0.75×, 1×, 1.25× và 1.5×.',
      ),
      _FaqItem(
        'Đổi ngôn ngữ thuyết minh ở đâu?',
        'Có hai đường: nút hình chữ dịch ở trang nghe thuyết minh, hoặc vào '
            'Tài khoản của tôi → Ngôn ngữ. Sidebar cũng có mục Ngôn ngữ.',
      ),
      _FaqItem(
        'Đi ra xa hiện vật thì còn xem được nội dung không?',
        'Còn. Nội dung đã tải sẽ tiếp tục xem được kể cả khi bạn ra ngoài vùng '
            'phủ sóng beacon, nên có thể đọc lại sau khi rời khu trưng bày.',
      ),
    ],
  ),
  _FaqGroup(
    title: 'Tài khoản',
    icon: Icons.person_outline,
    items: [
      _FaqItem(
        'Có bắt buộc đăng nhập mới dùng được không?',
        'Không. Khách tham quan xem được toàn bộ hiện vật, bản đồ, thuyết '
            'minh và nhận thông báo mà không cần tài khoản.',
      ),
      _FaqItem(
        'Vậy đăng nhập để làm gì?',
        'Để lưu danh sách hiện vật yêu thích và đồng bộ dữ liệu của bạn giữa '
            'các thiết bị. Lịch sử tham quan thì vẫn được lưu trên máy ngay cả '
            'khi bạn chưa đăng nhập.',
      ),
      _FaqItem(
        'Đăng nhập và đăng ký ở đâu?',
        'Vào Tài khoản của tôi, dùng hai nút "Đăng nhập" và "Đăng ký" ở đầu '
            'trang. Sidebar cũng có lối vào tương tự.',
      ),
    ],
  ),
  _FaqGroup(
    title: 'Bản đồ & vị trí',
    icon: Icons.map_outlined,
    items: [
      _FaqItem(
        'Bản đồ trống, không thấy gì cả?',
        'Bản đồ cần kết nối mạng để tải nền. Hãy kiểm tra Wi-Fi hoặc dữ liệu '
            'di động. Các ghim hiện vật vẫn hiện đúng vị trí dù nền bản đồ '
            'chưa tải xong.',
      ),
      _FaqItem(
        'Vì sao app xin quyền vị trí?',
        'Chỉ để hiển thị chấm vị trí của bạn trên bản đồ khu di tích, giúp bạn '
            'biết mình đang ở đâu so với các hiện vật. Từ chối quyền này thì '
            'bản đồ và ghim hiện vật vẫn dùng bình thường.',
      ),
      _FaqItem(
        'Lọc hiện vật theo khu trưng bày được không?',
        'Được. Ở tab Bản đồ có dải nút chọn khu vực phía trên; chọn một khu thì '
            'bản đồ chỉ hiện ghim của khu đó.',
      ),
    ],
  ),
  _FaqGroup(
    title: 'Thông báo & phản hồi',
    icon: Icons.notifications_outlined,
    items: [
      _FaqItem(
        'Xem lại thông báo đã nhận ở đâu?',
        'Bấm nút hình chuông ở góc trên bên phải trang Khám phá. Con số đỏ '
            'trên chuông là số thông báo chưa đọc.',
      ),
      _FaqItem(
        'Tôi muốn đánh giá một hiện vật hoặc góp ý về khu di tích.',
        'Với từng hiện vật: mở trang chi tiết rồi vào tab "Đánh giá". Với góp '
            'ý chung về khu di tích: vào Tài khoản của tôi → Đánh giá khu di '
            'tích.',
      ),
    ],
  ),
];
