import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _agreed = false;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng đồng ý với điều khoản sử dụng'),
      ));
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthController.instance.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _nameController.text,
      );
      // Số điện thoại không nằm trong RegisterDto của backend — lưu kèm vào
      // hồ sơ ngay sau khi có phiên.
      final phone = _phoneController.text.trim();
      if (phone.isNotEmpty) {
        await AuthController.instance.updateProfile(phone: phone);
      }
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        // Quay về màn trước đó (cổng đăng nhập / hồ sơ), giờ đã đăng nhập.
        navigator.popUntil((route) => route.isFirst);
      } else {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Bắt đầu hành trình khám phá di sản cùng chúng tôi',
                  style: TextStyle(fontSize: 14.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Họ và tên',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Vui lòng nhập email hợp lệ'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Số điện thoại',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().length < 9)
                      ? 'Số điện thoại không hợp lệ'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  // Khớp MinLength(8) của RegisterDto phía backend.
                  validator: (v) => (v == null || v.length < 8)
                      ? 'Mật khẩu tối thiểu 8 ký tự'
                      : null,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _agreed,
                  onChanged: (v) => setState(() => _agreed = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                  title: const Text.rich(
                    TextSpan(
                      text: 'Tôi đồng ý với ',
                      style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                      children: [
                        TextSpan(
                          text: 'Điều khoản sử dụng',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: ' và '),
                        TextSpan(
                          text: 'Chính sách bảo mật',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _busy ? null : _register,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Đăng ký'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Đã có tài khoản? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
