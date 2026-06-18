import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/vip_badge.dart';
import '../auth/auth_controller.dart';
import '../auth/login_screen.dart';
import 'home_controller.dart';
import '../wallet/wallet_screen.dart';
import '../vip/vip_screen.dart';

class ProfileTab extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;
  const ProfileTab({super.key, this.onNavigateToTab});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {

  Future<void> _launchURL(String urlString, bool isAr) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAr ? 'تعذر فتح الرابط' : 'Could not launch URL',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  void _showEditProfileDialog(String currentName, AuthController auth, HomeController home) {
    final ctrl = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();
    final isAr = !auth.isEnglish;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isAr ? 'تعديل اسم المستخدم' : 'Edit Username',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: ctrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
                      decoration: InputDecoration(
                        labelText: isAr ? 'اسم المستخدم الجديد' : 'New Username',
                        labelStyle: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return isAr ? 'الاسم مطلوب' : 'Name is required';
                        }
                        if (v.trim().length < 3) {
                          return isAr ? 'الاسم قصير جداً' : 'Name is too short';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isAr ? 'إلغاء' : 'Cancel',
                    style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() {});
                          final success = await auth.updateProfile(username: ctrl.text.trim());
                          if (success) {
                            await home.refreshDashboard();
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isAr ? 'تم التحديث بنجاح' : 'Updated successfully'),
                                  backgroundColor: AppColors.accent,
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              setDialogState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(auth.error ?? (isAr ? 'حدث خطأ ما' : 'Something went wrong')),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isAr ? 'حفظ' : 'Save',
                          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog(AuthController auth, HomeController home) {
    final isAr = !auth.isEnglish;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isAr ? 'تحذير هام!' : 'Warning!',
            style: const TextStyle(fontFamily: 'Cairo', color: AppColors.error, fontWeight: FontWeight.bold),
          ),
          content: Text(
            isAr
                ? 'هل أنت متأكد من رغبتك في حذف الحساب نهائياً؟ هذا الإجراء لا يمكن التراجع عنه وسيتم مسح كافة بياناتك وجوائزك.'
                : 'Are you sure you want to permanently delete your account? This action cannot be undone and all your coins and progress will be lost.',
            style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textPrimary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isAr ? 'إلغاء' : 'Cancel',
                style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await auth.deleteAccount();
                if (success) {
                  home.clearState();
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isAr ? 'تم حذف الحساب بنجاح' : 'Account deleted successfully'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(auth.error ?? (isAr ? 'حدث خطأ ما' : 'Something went wrong')),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isAr ? 'حذف نهائي' : 'Delete',
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(AuthController auth, HomeController home) {
    final isAr = !auth.isEnglish;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isAr ? 'تسجيل الخروج' : 'Logout',
            style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            isAr ? 'هل أنت متأكد من رغبتك في تسجيل الخروج؟' : 'Are you sure you want to log out?',
            style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isAr ? 'إلغاء' : 'Cancel',
                style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                home.clearState();
                auth.logout();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isAr ? 'خروج' : 'Logout',
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(String title, String content, bool isAr) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: const TextStyle(fontFamily: 'Cairo', color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isAr ? 'إغلاق' : 'Close',
                style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showGeneralSettingsDialog(BuildContext context, AuthController auth, HomeController home) {
    final isAr = !auth.isEnglish;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.settings_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'الإعدادات العامة' : 'General Settings',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Language Switch Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.language_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? 'لغة التطبيق' : 'App Language',
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                Text(
                                  isAr ? 'العربية' : 'English',
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: auth.isEnglish,
                          onChanged: (val) async {
                            setDialogState(() {});
                            final success = await auth.updateProfile(language: val ? 'en' : 'ar');
                            if (success) {
                              await home.refreshDashboard();
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                              Future.delayed(const Duration(milliseconds: 100), () {
                                if (context.mounted) {
                                  _showGeneralSettingsDialog(context, auth, home);
                                }
                              });
                            }
                          },
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.cardBorder),

                    // Notifications Switch Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? 'إعدادات الإشعارات' : 'Notifications',
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                Text(
                                  isAr ? 'تلقي التنبيهات والأخبار' : 'Receive alerts and news',
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: home.dashboard?.notificationsEnabled ?? true,
                          onChanged: (val) async {
                            setDialogState(() {});
                            final success = await auth.updateProfile(notificationsEnabled: val);
                            if (success) {
                              await home.refreshDashboard();
                            }
                            setDialogState(() {});
                          },
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.cardBorder),

                    // Logout Button
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.logout_rounded, color: AppColors.warning, size: 22),
                      title: Text(
                        isAr ? 'تسجيل الخروج' : 'Logout',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showLogoutDialog(auth, home);
                      },
                    ),
                    const Divider(height: 10, color: Colors.transparent),

                    // Delete Account Button
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 22),
                      title: Text(
                        isAr ? 'حذف الحساب نهائياً' : 'Delete Account permanently',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showDeleteAccountDialog(auth, home);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isAr ? 'إغلاق' : 'Close',
                    style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final auth = context.watch<AuthController>();
    final isAr = !auth.isEnglish;

    final String username = home.dashboard?.username ?? '---';
    final int userId = home.dashboard?.id ?? 0;
    final String vipTier = home.dashboard?.vipTier ?? 'FREE';
    final double balance = home.dashboard?.balance ?? 0.0;
    final String country = home.dashboard?.country ?? '';
    final String countryCode = home.dashboard?.countryCode ?? '';

    // Currency Conversion Calculations
    final bool isIraq = countryCode.toUpperCase() == 'IQ' ||
        country.toLowerCase().contains('iraq') ||
        country.contains('عراق');
    final double rate = isIraq ? 1600.0 : 1.0;
    final double equivalentValue = balance * rate;
    final String formattedEquivalent = isIraq
        ? '${NumberFormat('#,##0', 'en_US').format(equivalentValue)} د.ع'
        : '\$${NumberFormat('#,##0.00', 'en_US').format(equivalentValue)}';

    // Info dialogue texts
    final String aboutTitle = isAr ? 'حول التطبيق' : 'About App';
    final String aboutContent = isAr
        ? 'تطبيق A Plus Coins هو التطبيق العربي الرائد لربح المكافآت والعملات الرقمية من خلال مشاهدة الإعلانات وتأدية المهام اليومية البسيطة. يتيح لك التطبيق جمع العملات واستبدالها بالعديد من كروت الاتصال والألعاب والهدايا المميزة من المتجر.\n\nرقم الإصدار: 1.0.0'
        : 'A Plus Coins is the leading rewards app in the Arab world, allowing users to earn coins by watching advertisements and completing simple daily tasks. Redeem your accumulated coins for mobile cards, game vouchers, and premium rewards directly from the store.\n\nVersion: 1.0.0';



    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isAr ? 'الملف الشخصي' : 'Profile',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const SizedBox(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── User Information Header Card (Luxurious glow border & layout) ──
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Avatar with Premium Gradient Ring
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(2), // border thickness
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.background,
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.edit, size: 16, color: AppColors.primary),
                                onPressed: () => _showEditProfileDialog(username, auth, home),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${userId > 0 ? userId.toString().padLeft(6, '0') : '------'}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    VipBadge(tier: vipTier),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Services & Finance Section ──
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
                      ),
                      title: Text(
                        isAr ? 'المحفظة' : 'Wallet',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${balance.toStringAsFixed(0)} ${isAr ? 'كونز' : 'Coinz'} ($formattedEquivalent)',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WalletScreen()),
                        );
                      },
                    ),
                    const Divider(height: 8, color: AppColors.cardBorder),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.vip3.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.stars_rounded, color: AppColors.vip3, size: 20),
                      ),
                      title: Text(
                        isAr ? 'العضوية والترقية' : 'VIP Upgrade & Tiers',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${isAr ? 'الفئة الحالية' : 'Current Tier'}: $vipTier',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VipScreen()),
                        );
                      },
                    ),
                    const Divider(height: 8, color: AppColors.cardBorder),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_outline_rounded, color: AppColors.primary, size: 20),
                      ),
                      title: Text(
                        isAr ? 'برنامج الإحالة' : 'Referral Program',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        isAr ? 'شارك الكود الخاص بك واربح عمولات حرة' : 'Share your code & earn commissions',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                      onTap: () {
                        widget.onNavigateToTab?.call(2);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Settings & Support Section ──
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.settings_rounded, color: AppColors.textSecondary, size: 20),
                      ),
                      title: Text(
                        isAr ? 'الإعدادات العامة' : 'General Settings',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        isAr ? 'تبديل اللغة، الإشعارات، إدارة الحساب' : 'Language, notifications, account management',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                      onTap: () => _showGeneralSettingsDialog(context, auth, home),
                    ),
                    const Divider(height: 8, color: AppColors.cardBorder),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                      ),
                      title: Text(
                        isAr ? 'حول التطبيق' : 'About App',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                      onTap: () => _showInfoDialog(aboutTitle, aboutContent, isAr),
                    ),
                    const Divider(height: 8, color: AppColors.cardBorder),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 20),
                      ),
                      title: Text(
                        isAr ? 'سياسة الخصوصية' : 'Privacy Policy',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                      onTap: () => _launchURL('https://a94r98.github.io/aplus-coins-app/privacy.html', isAr),
                    ),
                    const Divider(height: 8, color: AppColors.cardBorder),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
                      ),
                      title: Text(
                        isAr ? 'شروط الخصوصية والاستخدام' : 'Terms of Use',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                      onTap: () => _launchURL('https://a94r98.github.io/aplus-coins-app/terms.html', isAr),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
