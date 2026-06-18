import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/gradient_button.dart';
import 'auth_controller.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenCtrl = TextEditingController();

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify(AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;
    
    final isAr = !auth.isEnglish;
    final ok = await auth.verifyEmail(_tokenCtrl.text.trim());
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم تفعيل حسابك بنجاح! يمكنك الآن تسجيل الدخول.' : 'Account verified successfully! You can now login.'),
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
          content: Text(auth.error ?? (isAr ? 'كود التفعيل غير صحيح أو منتهي الصلاحية' : 'Invalid or expired verification token')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _resend(AuthController auth) async {
    final isAr = !auth.isEnglish;
    final ok = await auth.resendVerification(widget.email);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم إرسال كود تفعيل جديد!' : 'New verification code has been sent!'),
          backgroundColor: AppColors.accent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? (isAr ? 'فشل إعادة الإرسال' : 'Failed to resend')),
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
                        onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        ),
                        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                      ),
                      Expanded(
                        child: Text(
                          isAr ? 'تفعيل الحساب' : 'Verify Account',
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          const Icon(Icons.mark_email_unread_outlined, size: 80, color: AppColors.primary),
                          const SizedBox(height: 24),
                          Text(
                            isAr ? 'تأكيد البريد الإلكتروني' : 'Confirm Your Email',
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
                                ? 'تم إرسال رمز التفعيل إلى بريدك:\n${widget.email}'
                                : 'A verification token has been sent to:\n${widget.email}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 40),
                          TextFormField(
                            controller: _tokenCtrl,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              labelText: isAr ? 'رمز التفعيل' : 'Verification Token',
                              prefixIcon: const Icon(Icons.security),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? (isAr ? 'الرجاء إدخال الرمز' : 'Token is required')
                                : null,
                          ),
                          const SizedBox(height: 30),
                          GradientButton(
                            text: isAr ? 'تأكيد الحساب' : 'Verify Account',
                            isLoading: auth.isLoading,
                            onPressed: auth.isLoading ? null : () => _verify(auth),
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: auth.isLoading ? null : () => _resend(auth),
                            child: Text(
                              isAr ? 'إعادة إرسال الرمز' : 'Resend Verification Code',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
