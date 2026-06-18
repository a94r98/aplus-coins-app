import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/gradient_button.dart';
import 'auth_controller.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _codeSent = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode(AuthController auth) async {
    if (!_emailFormKey.currentState!.validate()) return;

    final isAr = !auth.isEnglish;
    final ok = await auth.forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم إرسال رمز استعادة كلمة المرور!' : 'Password reset code has been sent!'),
          backgroundColor: AppColors.accent,
        ),
      );
      setState(() {
        _codeSent = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? (isAr ? 'البريد الإلكتروني غير مسجل' : 'Email is not registered')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _resetPassword(AuthController auth) async {
    if (!_resetFormKey.currentState!.validate()) return;

    final isAr = !auth.isEnglish;
    final ok = await auth.resetPassword(
      _tokenCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم تغيير كلمة المرور بنجاح!' : 'Password has been updated successfully!'),
          backgroundColor: AppColors.accent,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? (isAr ? 'الرمز غير صالح أو منتهي الصلاحية' : 'Invalid or expired token')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isAr = !auth.isEnglish;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F172A), Color(0xFF00264D), Color(0xFF0F172A)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                      ),
                      Expanded(
                        child: Text(
                          isAr ? 'استعادة كلمة المرور' : 'Reset Password',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _codeSent ? _buildResetForm(auth, isAr) : _buildEmailRequestForm(auth, isAr),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailRequestForm(AuthController auth, bool isAr) {
    return Form(
      key: _emailFormKey,
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.lock_reset_outlined, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            isAr ? 'هل نسيت كلمة المرور؟' : 'Forgot Password?',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isAr
                ? 'أدخل بريدك الإلكتروني لإرسال كود استعادة كلمة المرور.'
                : 'Enter your email to receive a password reset token.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
            decoration: InputDecoration(
              labelText: isAr ? 'البريد الإلكتروني' : 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return isAr ? 'البريد مطلوب' : 'Email is required';
              if (!v.contains('@')) return isAr ? 'بريد غير صالح' : 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 30),
          GradientButton(
            text: isAr ? 'إرسال رمز الاستعادة' : 'Send Reset Token',
            isLoading: auth.isLoading,
            onPressed: auth.isLoading ? null : () => _sendCode(auth),
          ),
        ],
      ),
    );
  }

  Widget _buildResetForm(AuthController auth, bool isAr) {
    return Form(
      key: _resetFormKey,
      child: Column(
        children: [
          const SizedBox(height: 30),
          const Icon(Icons.vpn_key_outlined, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            isAr ? 'إعادة تعيين كلمة المرور' : 'Create New Password',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isAr
                ? 'أدخل الرمز المرسل إلى بريدك الإلكتروني مع كلمة المرور الجديدة.'
                : 'Enter the token sent to your email and choose a new password.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _tokenCtrl,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              labelText: isAr ? 'رمز الاستعادة' : 'Reset Token',
              prefixIcon: const Icon(Icons.security),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? (isAr ? 'الرجاء إدخال رمز الاستعادة' : 'Reset token is required')
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
            decoration: InputDecoration(
              labelText: isAr ? 'كلمة المرور الجديدة' : 'New Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return isAr ? 'كلمة المرور مطلوبة' : 'Password is required';
              if (v.length < 8) return isAr ? 'يجب أن تكون 8 أحرف على الأقل' : 'Minimum 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 30),
          GradientButton(
            text: isAr ? 'تحديث كلمة المرور' : 'Update Password',
            isLoading: auth.isLoading,
            onPressed: auth.isLoading ? null : () => _resetPassword(auth),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => setState(() => _codeSent = false),
            child: Text(
              isAr ? 'رجوع لتغيير البريد' : 'Change Email Address',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
