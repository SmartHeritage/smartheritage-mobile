import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  /// Backend dùng enum MALE/FEMALE/OTHER, màn hình hiện nhãn tiếng Việt.
  static const _genderLabels = {
    'MALE': 'Nam',
    'FEMALE': 'Nữ',
    'OTHER': 'Khác',
  };

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  String? _gender;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final user = AuthController.instance.user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _gender = user?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await AuthController.instance.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        gender: _gender,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đã cập nhật thông tin cá nhân'),
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa thông tin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceTint,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.mint, width: 2),
                    ),
                    child: const Icon(Icons.person,
                        size: 56, color: AppColors.primary),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 17, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _fieldLabel('Họ và tên'),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 18),
            _fieldLabel('Email'),
            TextField(
              controller: _emailController,
              // Đổi email là đổi định danh đăng nhập — không mở ở màn hình này.
              readOnly: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 18),
            _fieldLabel('Số điện thoại'),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 18),
            _fieldLabel('Giới tính'),
            Row(
              children: [
                for (final entry in _genderLabels.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: _gender == entry.key,
                      onSelected: (_) => setState(() => _gender = entry.key),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _gender == entry.key
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
