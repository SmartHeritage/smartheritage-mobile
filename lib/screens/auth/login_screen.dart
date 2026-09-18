import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await AuthController.instance.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      // Lấy messenger TRƯỚC khi điều hướng: pop xong thì context của màn này
      // chết, còn messenger gốc của MaterialApp vẫn sống nên snackbar hiện
      // được ở màn hình vừa quay về.
      final messenger = ScaffoldMessenger.of(context);
      _leaveLoginScreen();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Đăng nhập thành công')),
        );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(errorSnackBar(e.message));
    }
  }

  void _leaveLoginScreen() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      // Được mở như một "cổng đăng nhập" — trả về nơi đã gọi.
      navigator.pop(true);
    } else {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    }
  }

  void _notSupportedYet() {
    ScaffoldMessenger.of(context)
        .showSnackBar(errorSnackBar('Đăng nhập Google chưa được hỗ trợ'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Chào mừng trở lại!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đăng nhập để đồng bộ lịch sử tham quan\nvà cá nhân hoá trải nghiệm của bạn',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
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
                  // Backend đặt tối thiểu 8 ký tự — chặn ngay ở đây để khỏi
                  // đi một vòng mạng chỉ để nhận lỗi 400.
                  validator: (v) => (v == null || v.length < 8)
                      ? 'Mật khẩu tối thiểu 8 ký tự'
                      : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _busy ? null : _login,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Đăng nhập'),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'hoặc tiếp tục với',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  // Trước đây nút này gọi thẳng _login và giả lập đăng nhập.
                  // Auth đã chạy thật nên không thể fake được nữa.
                  onPressed: _notSupportedYet,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider, width: 1.4),
                    foregroundColor: AppColors.textPrimary,
                  ),
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    width: 22,
                    height: 22,
                  ),
                  label: const Text(
                    'Tiếp tục với Google',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Chưa có tài khoản? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text(
                        'Đăng ký ngay',
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
