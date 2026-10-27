import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/api_client.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';

/// Bắt tài khoản Google nhập số điện thoại trước khi dùng app.
///
/// Google không trả số điện thoại nên backend tạo tài khoản không có số; màn
/// này ghi nó qua `PATCH /auth/me`. Không bỏ qua được: thoát ra (nút back,
/// vuốt back, "Dùng tài khoản khác") là đăng xuất luôn, để không có phiên
/// Google nào dùng app mà thiếu số.
class CompletePhoneScreen extends StatefulWidget {
  const CompletePhoneScreen({super.key});

  /// Mở màn này nếu tài khoản đang đăng nhập còn thiếu số. Trả về `true` khi
  /// đã có số (sẵn hoặc vừa nhập), `false` khi người dùng bỏ ra (đã đăng xuất).
  static Future<bool> ensure(BuildContext context) async {
    final auth = AuthController.instance;
    if (!(auth.user?.needsPhone ?? false)) return auth.isLoggedIn;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CompletePhoneScreen()),
    );
    return (result ?? false) && auth.isLoggedIn;
  }

  @override
  State<CompletePhoneScreen> createState() => _CompletePhoneScreenState();
}

class _CompletePhoneScreenState extends State<CompletePhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await AuthController.instance.updateProfile(
        phone: _phoneController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(errorSnackBar(e.message));
      // Phiên bị thu hồi giữa chừng → không còn gì để hoàn tất.
      if (!AuthController.instance.isLoggedIn) Navigator.of(context).pop(false);
    }
  }

  Future<void> _leave() async {
    // Không chờ đăng xuất xong: logout luôn xoá phiên local trước rồi mới gọi
    // mạng, nên rời màn ngay là an toàn kể cả khi mất mạng.
    unawaited(AuthController.instance.logout());
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _busy) return;
        _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: BackButton(onPressed: _busy ? null : _leave),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Center(
                    child: Icon(
                      Icons.phone_iphone_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.completePhoneTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.completePhoneSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    // Backend giới hạn 32 ký tự — quá thì 400.
                    maxLength: 32,
                    decoration: InputDecoration(
                      hintText: context.l10n.fieldPhone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      counterText: '',
                    ),
                    // Cùng luật với màn đăng ký.
                    validator: (v) => (v == null || v.trim().length < 9)
                        ? context.l10n.invalidPhone
                        : null,
                    onFieldSubmitted: (_) => _busy ? null : _submit(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(context.l10n.completePhoneSubmit),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _busy ? null : _leave,
                    child: Text(context.l10n.completePhoneUseOtherAccount),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
