import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/api/api_service.dart';
import '../../core/api/endpoints.dart';
import '../../shared/widgets/gradient_button.dart';
import 'auth_controller.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  String _selectedCountry = 'Saudi Arabia';
  String _selectedCountryCode = '+966';
  bool _obscurePassword = true;

  List<Map<String, String>> _dynamicCountries = [
    {'name': 'Saudi Arabia', 'code': '+966', 'flag': '🇸🇦', 'rawCode': 'SA'},
    {'name': 'UAE', 'code': '+971', 'flag': '🇦🇪', 'rawCode': 'AE'},
    {'name': 'Iraq', 'code': '+964', 'flag': '🇮🇶', 'rawCode': 'IQ'},
    {'name': 'Turkey', 'code': '+90', 'flag': '🇹🇷', 'rawCode': 'TR'},
  ];
  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  Future<void> _fetchCountries() async {
    try {
      final ApiService apiService = ApiService();
      final res = await apiService.get(Endpoints.getCountries);
      if (res['status'] == 'success' && res['data'] is List) {
        final List<dynamic> list = res['data'];
        final List<Map<String, String>> mapped = list.map((item) {
          final code = item['code'] as String;
          final dialCode = item['dial_code'] as String? ?? '+1';
          final flag = item['flag'] as String? ?? '🌍';
          
          return {
            'name': item['name'] as String,
            'code': dialCode,
            'rawCode': code,
            'flag': flag,
          };
        }).toList();

        if (mapped.isNotEmpty) {
          setState(() {
            _dynamicCountries = mapped;
            final defaultIdx = mapped.indexWhere((c) => c['rawCode'] == 'SA');
            if (defaultIdx != -1) {
              _selectedCountry = mapped[defaultIdx]['name']!;
              _selectedCountryCode = mapped[defaultIdx]['code']!;
            } else {
              _selectedCountry = mapped[0]['name']!;
              _selectedCountryCode = mapped[0]['code']!;
            }
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    _passwordCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _doRegister(AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;
    
    final countryItem = _dynamicCountries.firstWhere(
      (c) => c['name'] == _selectedCountry,
      orElse: () => {'name': _selectedCountry, 'code': _selectedCountryCode, 'rawCode': 'SA'},
    );
    final rawCode = countryItem['rawCode'] ?? 'SA';
    final isAr = !auth.isEnglish;

    final ok = await auth.register(
      username: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      phone: _phoneCtrl.text.trim(),
      country: _selectedCountry,
      countryCode: rawCode,
      age: int.tryParse(_ageCtrl.text.trim()) ?? 18,
      referralCode: _referralCtrl.text.trim().isEmpty ? null : _referralCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم إنشاء الحساب بنجاح!' : 'Registered successfully!'),
          backgroundColor: AppColors.accent,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? (isAr ? 'فشل إنشاء الحساب' : 'Failed to register')),
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
          child: Column(
            children: [
                // Header
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
                          isAr ? 'إنشاء حساب جديد' : 'Create Account',
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
                          const SizedBox(height: 8),
                          // Full Name
                          TextFormField(
                            controller: _nameCtrl,
                            style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
                            decoration: InputDecoration(
                              labelText: isAr ? 'الاسم الكامل' : 'Full Name',
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? (isAr ? 'الاسم مطلوب' : 'Name is required')
                                : null,
                          ),
                          const SizedBox(height: 14),
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
                              if (v == null || v.trim().isEmpty) return isAr ? 'البريد مطلوب' : 'Email required';
                              if (!v.contains('@')) return isAr ? 'بريد غير صالح' : 'Invalid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          // Country dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedCountry,
                            dropdownColor: AppColors.surface,
                            style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
                            decoration: InputDecoration(
                              labelText: isAr ? 'الدولة' : 'Country',
                              prefixIcon: const Icon(Icons.flag_outlined),
                            ),
                            items: _dynamicCountries.map((c) => DropdownMenuItem(
                              value: c['name'],
                              child: Text('${c['flag']} ${c['name']}',
                                  style: const TextStyle(fontFamily: 'Cairo')),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedCountry = val;
                                  _selectedCountryCode = _dynamicCountries
                                      .firstWhere((c) => c['name'] == val)['code']!;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          // Phone
                          Row(
                            children: [
                              Container(
                                height: 56,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Center(
                                  child: Text(
                                    _selectedCountryCode,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Cairo',
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
                                  decoration: InputDecoration(
                                    labelText: isAr ? 'رقم الهاتف' : 'Phone Number',
                                    prefixIcon: const Icon(Icons.phone_outlined),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? (isAr ? 'الهاتف مطلوب' : 'Phone required')
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Age
                          TextFormField(
                            controller: _ageCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
                            decoration: InputDecoration(
                              labelText: isAr ? 'العمر' : 'Age',
                              prefixIcon: const Icon(Icons.cake_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return isAr ? 'العمر مطلوب' : 'Age required';
                              final age = int.tryParse(v.trim());
                              if (age == null || age < 16 || age > 100) {
                                return isAr ? 'العمر يجب أن يكون بين 16-100' : 'Age must be 16-100';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
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
                              if (v == null || v.isEmpty) return isAr ? 'كلمة المرور مطلوبة' : 'Password required';
                              if (v.length < 8) return isAr ? 'يجب أن تكون 8 أحرف على الأقل' : 'Minimum 8 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          // Referral code (optional)
                          TextFormField(
                            controller: _referralCtrl,
                            style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
                            decoration: InputDecoration(
                              labelText: isAr ? 'رمز الإحالة (اختياري)' : 'Referral Code (optional)',
                              prefixIcon: const Icon(Icons.card_giftcard_outlined),
                            ),
                          ),
                          const SizedBox(height: 30),
                          GradientButton(
                            text: isAr ? 'إنشاء الحساب' : 'Create Account',
                            isLoading: auth.isLoading,
                            onPressed: auth.isLoading ? null : () => _doRegister(auth),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isAr ? 'لديك حساب بالفعل؟ ' : 'Already have an account? ',
                                style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo'),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Text(
                                  isAr ? 'تسجيل الدخول' : 'Login',
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
              ],
            ),
          ),
        ),
      );
    }
  }
