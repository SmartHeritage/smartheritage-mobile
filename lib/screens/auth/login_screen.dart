import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/api_client.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../main_shell.dart';
import 'complete_phone_screen.dart';
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
      final success = context.l10n.loginSuccess;
      _leaveLoginScreen();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(success)),
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

  Future<void> _loginWithGoogle() async {
    setState(() => _busy = true);
    try {
      final ok = await AuthController.instance.signInWithGoogle();
      if (!mounted) return;
      if (!ok) {
        // Huỷ màn chọn tài khoản — ở lại màn đăng nhập, không báo lỗi.
        setState(() => _busy = false);
        return;
      }
      // Google không cho số điện thoại → bắt nhập ngay. Bỏ ra thì màn kia đã
      // đăng xuất, ở lại đây để chọn cách đăng nhập khác.
      if (!await CompletePhoneScreen.ensure(context)) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final success = context.l10n.loginSuccess;
      _leaveLoginScreen();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(success)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(errorSnackBar(e.message));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar trong suốt, không tiêu đề: chỉ để lấy nút back. Màn hình này
      // luôn được push (từ AuthController.ensureLoggedIn), nên không có nút
      // quay lại thì khách bị kẹt, phải đăng nhập mới thoát ra được.
      // AppBar tự ẩn nút khi không pop được, nên đây vẫn an toàn nếu sau này
      // có luồng mở thẳng vào màn đăng nhập.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Trước là 40; AppBar đã chiếm phần khoảng thở phía trên.
                const SizedBox(height: 8),
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
                Text(
                  context.l10n.loginWelcome,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: context.l10n.fieldEmail,
                    prefixIcon: const Icon(Icons.mail_outline),
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? context.l10n.invalidEmail
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: context.l10n.fieldPassword,
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
                      ? context.l10n.passwordTooShort
                      : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(context.l10n.forgotPassword),
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
                      : Text(context.l10n.login),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        context.l10n.orContinueWith,
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
                  // Khoá chung với nút đăng nhập email: hai luồng cùng ghi
                  // phiên, không cho chạy chồng.
                  onPressed: _busy ? null : _loginWithGoogle,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider, width: 1.4),
                    foregroundColor: AppColors.textPrimary,
                  ),
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    width: 22,
                    height: 22,
                  ),
                  label: Text(
                    context.l10n.continueWithGoogle,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.l10n.noAccount,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: Text(
                        context.l10n.registerNow,
                        style: const TextStyle(
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
