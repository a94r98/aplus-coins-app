import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/gradient_button.dart';
import 'auth_controller.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin(AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'فشل تسجيل الدخول'),
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
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Align(
                    alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => context.read<AuthController>().toggleLocale(),
                      icon: const Icon(Icons.language, color: AppColors.textSecondary, size: 18),
                      label: Text(
                        isAr ? 'English' : 'عربي',
                        style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Logo / Icon
                  Container(
                    width: 95,
                    height: 95,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                    const SizedBox(height: 24),
                    Text(
                      isAr ? 'مرحباً بعودتك' : 'Welcome Back',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAr ? 'سجّل دخولك للمتابعة' : 'Sign in to continue',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
                      decoration: InputDecoration(
                        labelText: isAr ? 'البريد الإلكتروني' : 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return isAr ? 'البريد مطلوب' : 'Email is required';
                        }
                        if (!v.contains('@')) {
                          return isAr ? 'بريد غير صالح' : 'Invalid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Password
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
                      decoration: InputDecoration(
                        labelText: isAr ? 'كلمة المرور' : 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return isAr ? 'كلمة المرور مطلوبة' : 'Password is required';
                        }
                        if (v.length < 6) {
                          return isAr ? 'يجب أن تكون 6 أحرف على الأقل' : 'Minimum 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        ),
                        child: Text(
                          isAr ? 'نسيت كلمة المرور؟' : 'Forgot Password?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      text: isAr ? 'تسجيل الدخول' : 'Login',
                      isLoading: auth.isLoading,
                      onPressed: auth.isLoading ? null : () => _doLogin(auth),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isAr ? 'ليس لديك حساب؟ ' : "Don't have an account? ",
                          style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo'),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                          child: Text(
                            isAr ? 'إنشاء حساب' : 'Register',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
