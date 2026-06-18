import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import '../auth/auth_controller.dart';
import 'home_controller.dart';
import 'store_tab.dart';
import 'referral_tab.dart';
import 'profile_tab.dart';
import 'notification_screen.dart';
import '../wallet/wallet_screen.dart';
import '../ads/ads_screen.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/secure_storage.dart';
import '../../core/api/api_service.dart';
import '../../core/api/endpoints.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeDashboardTab(onNavigateToTab: (index) {
        setState(() {
          _currentIndex = index;
        });
      }),
      const StoreTab(),
      const ReferralTab(),
      ProfileTab(onNavigateToTab: (index) {
        setState(() {
          _currentIndex = index;
        });
      }),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final home = context.read<HomeController>();
      await home.refreshDashboard();
      if (mounted) {
        final auth = context.read<AuthController>();
        if (home.dashboard != null) {
          auth.setLocale(home.dashboard!.language == 'en');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isAr = !auth.isEnglish;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            // Auto refresh state on screen/tab switch to preserve SSOT integrity
            if (index == 0 || index == 2) {
              context.read<HomeController>().refreshDashboard();
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_filled),
              label: isAr ? 'الرئيسية' : 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.storefront),
              label: isAr ? 'المتجر' : 'Store',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people),
              label: isAr ? 'الاحالة' : 'Referral',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: isAr ? 'الملف الشخصي' : 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeDashboardTab extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;
  const HomeDashboardTab({super.key, this.onNavigateToTab});

  @override
  State<HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends State<HomeDashboardTab> {
  final ApiService _apiService = ApiService();
  List<dynamic> _oneTimeTasks = [];
  bool _isOneTimeTasksLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchOneTimeTasks();
  }

  Future<void> _fetchOneTimeTasks() async {
    if (mounted) {
      setState(() {
        _isOneTimeTasksLoading = true;
      });
    }
    try {
      final res = await _apiService.get(Endpoints.oneTimeTasks);
      if (res['status'] == 'success' && res.containsKey('data')) {
        if (mounted) {
          setState(() {
            _oneTimeTasks = res['data'] as List<dynamic>;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching one time tasks: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isOneTimeTasksLoading = false;
        });
      }
    }
  }

  void _startTaskCountdown(Map<String, dynamic> task, bool isAr) async {
    final urlStr = task['url']?.toString() ?? '';

    // Launch url
    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $urlStr';
      }
    } catch (e) {
      debugPrint('Error launching url: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تعذر فتح الرابط.' : 'Could not open link.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Show countdown overlay dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _CountdownDialog(
          task: task,
          isAr: isAr,
          onClaimed: () {
            _fetchOneTimeTasks();
            context.read<HomeController>().refreshDashboard();
          },
        );
      },
    );
  }

  void _shareAppLinkAndClaim(HomeController home, bool isAr) async {
    final referralCode = home.dashboard?.referralCode ?? '';
    final message = isAr
        ? 'انضم إلي في تطبيق A Plus Coins لربح المكافآت بمشاهدة الإعلانات. استعمل كودي ($referralCode) للتسجيل والبدء بالربح:\nhttps://apluscoins.com'
        : 'Join me on A Plus Coins to earn rewards by watching simple ads. Use my referral code ($referralCode) to register and start earning:\nhttps://apluscoins.com';

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAr ? 'مشاركة رابط التطبيق' : 'Share App Link',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // WhatsApp Share
                    InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        final url = 'whatsapp://send?text=${Uri.encodeComponent(message)}';
                        final fallbackUrl = 'https://wa.me/?text=${Uri.encodeComponent(message)}';
                        try {
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
                          }
                        } catch (e) {
                          debugPrint('Error sharing via WhatsApp: $e');
                        }
                        
                        _claimShareAppReward(home, isAr);
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chat_bubble_outline, color: Colors.green, size: 30),
                          ),
                          const SizedBox(height: 8),
                          const Text('WhatsApp', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    // Telegram Share
                    InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        final url = 'https://t.me/share/url?url=https://apluscoins.com&text=${Uri.encodeComponent(message)}';
                        try {
                          final uri = Uri.parse(url);
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          debugPrint('Error sharing via Telegram: $e');
                        }
                        
                        _claimShareAppReward(home, isAr);
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.telegram, color: Colors.blue, size: 30),
                          ),
                          const SizedBox(height: 8),
                          const Text('Telegram', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _claimShareAppReward(HomeController home, bool isAr) async {
    final success = await home.claimShareApp();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr 
              ? 'تمت المشاركة وكسب 5 عملات بنجاح! 🎉'
              : 'Shared and earned 5 coins successfully! 🎉'),
          backgroundColor: AppColors.accent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(home.error ?? (isAr ? 'فشل كسب المكافأة' : 'Failed to claim reward')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildOneTimeTasksSection(bool isAr) {
    if (_isOneTimeTasksLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_oneTimeTasks.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAr ? 'المهام لمرة واحدة' : 'One-Time Tasks',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._oneTimeTasks.map((t) {
          final task = t as Map<String, dynamic>;
          final isCompleted = task['is_completed'] as bool? ?? false;
          final reward = task['reward_amount']?.toString() ?? '0.10';
          final title = isAr ? task['arabic_title'] : task['title'];

          IconData icon = Icons.link_rounded;
          final taskKey = task['task_key']?.toString().toLowerCase() ?? '';
          if (taskKey.contains('whatsapp')) {
            icon = Icons.chat_bubble_outline;
          } else if (taskKey.contains('telegram')) {
            icon = Icons.telegram;
          } else if (taskKey.contains('facebook')) {
            icon = Icons.facebook;
          } else if (taskKey.contains('instagram')) {
            icon = Icons.camera_alt_outlined;
          } else if (taskKey.contains('tiktok')) {
            icon = Icons.music_note;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: _buildTaskItem(
              icon: icon,
              title: title,
              subtitle: isAr
                  ? 'انقر للزيارة واحصل على المكافأة بعد المتابعة'
                  : 'Click to visit and follow for a one-time reward',
              reward: '+$reward',
              actionWidget: isCompleted
                  ? Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF10B981),
                      ),
                      child: const Icon(Icons.check, size: 14, color: Colors.white),
                    )
                  : ElevatedButton(
                      onPressed: () => _startTaskCountdown(task, isAr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isAr ? 'بدء' : 'Start',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
              isAr: isAr,
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final auth = context.watch<AuthController>();
    final isAr = !auth.isEnglish;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await home.refreshDashboard();
            await _fetchOneTimeTasks();
          },
          color: AppColors.primary,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => widget.onNavigateToTab?.call(3),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF2FD3C6), width: 2),
                            ),
                            child: const CircleAvatar(
                              radius: 28,
                              backgroundColor: Color(0x1F009EB3),
                              backgroundImage: AssetImage('assets/images/avatar_3d.png'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr 
                                    ? 'مرحباً، ${home.dashboard?.username ?? 'أحمد'} 👋'
                                    : 'Welcome, ${home.dashboard?.username ?? 'User'} 👋',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                isAr ? 'واصل التقدم واربح المزيد من العملات' : 'Keep going and earn more coins',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: AppColors.primary,
                              size: 26,
                            ),
                          ),
                          if (home.hasUnreadNotifications)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (home.banners.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 140,
                    child: PageView.builder(
                      itemCount: home.banners.length,
                      controller: PageController(viewportFraction: 0.92),
                      itemBuilder: (context, index) {
                        final banner = home.banners[index];
                        final isLocalAsset = banner.imageUrl.startsWith('assets/');
                        return GestureDetector(
                          onTap: () async {
                            final success = await home.claimBannerClick();
                            if (!context.mounted) return;
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isAr 
                                      ? 'تم كسب 10 عملات لنقر الإعلان! 🎉'
                                      : 'Earned 10 coins for clicking the ad banner! 🎉'),
                                  backgroundColor: AppColors.accent,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(home.error ?? (isAr
                                      ? 'لقد وصلت للحد الأقصى للمكافآت اليوم (3 مرات)'
                                      : 'You have reached the limit of banner rewards today (3 times)')),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                            if (banner.actionUrl.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isAr 
                                      ? 'الانتقال إلى: ${banner.actionUrl}'
                                      : 'Navigating to: ${banner.actionUrl}'),
                                ),
                              );
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                image: isLocalAsset
                                    ? AssetImage(banner.imageUrl) as ImageProvider
                                    : NetworkImage(banner.imageUrl) as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.6),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    banner.title,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    banner.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 10,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2FD3C6), Color(0xFF009EB3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF009EB3).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Image.asset(
                          'assets/images/coins_stack_3d.png',
                          width: 48,
                          height: 48,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              home.dashboard != null
                                  ? CurrencyFormatter.format(home.dashboard!.balance, home.dashboard!.country, isAr)
                                  : '0',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              home.dashboard != null
                                  ? CurrencyFormatter.getLabel(home.dashboard!.country, isAr)
                                  : (isAr ? 'الرصيد' : 'Balance'),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const WalletScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.account_balance_wallet, size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                isAr ? 'محفظتي 〉' : 'My Wallet 〉',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdsScreen(hideAppBar: false)),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2FD3C6), Color(0xFF009EB3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF009EB3).withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Color(0xFF009EB3),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'شاهد إعلان واربح' : 'Watch Ad & Earn',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                isAr 
                                    ? 'المتبقي اليوم: ${home.dashboard != null ? (home.dashboard!.maxDailyAds - home.dashboard!.adsWatchedToday).clamp(0, 1000) : 0} / ${home.dashboard?.maxDailyAds ?? 0}'
                                    : 'Remaining today: ${home.dashboard != null ? (home.dashboard!.maxDailyAds - home.dashboard!.adsWatchedToday).clamp(0, 1000) : 0} / ${home.dashboard?.maxDailyAds ?? 0}',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                        const SizedBox(width: 8),
                        Image.asset(
                          'assets/images/gift_box_3d.png',
                          width: 48,
                          height: 48,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'المهام اليومية' : 'Daily Tasks',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTaskItem(
                  icon: Icons.calendar_today_rounded,
                  title: isAr ? 'تسجيل الدخول اليومي' : 'Daily Check-in',
                  subtitle: isAr ? 'سجل دخولك يومياً واكسب ٥ عملات' : 'Check in daily and earn 5 coins',
                  reward: '+5',
                  actionWidget: (home.tasksStatus?.checkInClaimed ?? false)
                      ? Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF10B981),
                          ),
                          child: const Icon(Icons.check, size: 14, color: Colors.white),
                        )
                      : ElevatedButton(
                          onPressed: () async {
                            final success = await home.claimCheckIn();
                            if (!context.mounted) return;
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isAr 
                                      ? 'تم تسجيل الدخول بنجاح وكسب 5 عملات! 🎉'
                                      : 'Checked in successfully and earned 5 coins! 🎉'),
                                  backgroundColor: AppColors.accent,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            isAr ? 'تسجيل' : 'Check-in',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                  isAr: isAr,
                ),
                const SizedBox(height: 10),
                _buildTaskItem(
                  icon: Icons.ads_click,
                  title: isAr ? 'شاهد وانقر على بنر الإعلانات' : 'Click Ad Banners',
                  subtitle: isAr ? 'انقر على بنر إعلاني (٣ مرات يومياً)' : 'Click on ad banners (3 times daily)',
                  reward: '+10',
                  actionWidget: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009EB3).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${home.tasksStatus?.bannerClicksCount ?? 0}/3',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF009EB3),
                      ),
                    ),
                  ),
                  isAr: isAr,
                ),
                const SizedBox(height: 10),
                _buildTaskItem(
                  icon: Icons.people_outline_rounded,
                  title: isAr ? 'ادعُ صديقاً' : 'Invite a Friend',
                  subtitle: isAr ? 'لكل صديق يسجل برمزك (مفتوح)' : 'For each friend registered (unlimited)',
                  reward: '+5',
                  actionWidget: ElevatedButton(
                    onPressed: () {
                      if (widget.onNavigateToTab != null) {
                        widget.onNavigateToTab!(2);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      isAr ? 'دعوة' : 'Invite',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  isAr: isAr,
                ),
                const SizedBox(height: 10),
                _buildTaskItem(
                  icon: Icons.share_rounded,
                  title: isAr ? 'مشاركة رابط التطبيق' : 'Share App Link',
                  subtitle: isAr ? 'شارك رابط التطبيق واكسب ٥ عملات' : 'Share the app link and earn 5 coins',
                  reward: '+5',
                  actionWidget: (home.tasksStatus?.shareAppClaimed ?? false)
                      ? Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF10B981),
                          ),
                          child: const Icon(Icons.check, size: 14, color: Colors.white),
                        )
                      : ElevatedButton(
                          onPressed: () => _shareAppLinkAndClaim(home, isAr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            isAr ? 'مشاركة' : 'Share',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                  isAr: isAr,
                ),
                const SizedBox(height: 12),
                _buildOneTimeTasksSection(isAr),
                const SizedBox(height: 12),
                if (home.unclaimedRewards.isNotEmpty) ...[
                  Text(
                    isAr ? 'الأرباح اليومية المستقرة الجاهزة للمطالبة' : 'Settled Daily Rewards Ready to Claim',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: home.unclaimedRewards.length,
                    itemBuilder: (context, index) {
                      final reward = home.unclaimedRewards[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr ? 'أرباح تسوية يوم ${reward.shareDate}' : 'Settlement for ${reward.shareDate}',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(reward.poolShareAmount, home.dashboard?.country ?? '', isAr),
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: home.isLoading
                                    ? null
                                    : () async {
                                        try {
                                          await home.claimDailyReward(reward.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(isAr
                                                    ? 'تمت إضافة المكافأة بنجاح!'
                                                    : 'Reward claimed successfully!'),
                                                backgroundColor: AppColors.accent,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(e.toString()),
                                                backgroundColor: AppColors.error,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(80, 36),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  isAr ? 'مطالبة' : 'Claim',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String reward,
    required Widget actionWidget,
    required bool isAr,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF009EB3).withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF009EB3), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                reward,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF009EB3),
                ),
              ),
              const SizedBox(width: 4),
              const Text('🟡', style: TextStyle(fontSize: 10)),
            ],
          ),
          const SizedBox(width: 14),
          actionWidget,
        ],
      ),
    );
  }
}

class _CountdownDialog extends StatefulWidget {
  final Map<String, dynamic> task;
  final bool isAr;
  final VoidCallback onClaimed;

  const _CountdownDialog({
    required this.task,
    required this.isAr,
    required this.onClaimed,
  });

  @override
  State<_CountdownDialog> createState() => _CountdownDialogState();
}

class _CountdownDialogState extends State<_CountdownDialog> {
  int _secondsRemaining = 15;
  bool _canClaim = false;
  bool _isLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = widget.task['cooldown_seconds'] as int? ?? 15;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _canClaim = true;
          });
        }
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _claimReward() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final apiService = ApiService();
      final deviceFingerprint = await SecureStorage.getDeviceFingerprint();
      
      final res = await apiService.post(
        Endpoints.claimOneTimeTask,
        body: {
          'taskKey': widget.task['task_key'],
          'deviceFingerprint': deviceFingerprint,
        },
      );

      if (res['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isAr
                  ? 'تم استلام مكافأة المهمة بنجاح! 🎉'
                  : 'Task reward claimed successfully! 🎉'),
              backgroundColor: AppColors.accent,
            ),
          );
          widget.onClaimed();
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? (widget.isAr ? 'فشلت عملية المطالبة' : 'Claim failed')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isAr ? widget.task['arabic_title'] : widget.task['title'];
    final reward = widget.task['reward_amount']?.toString() ?? '0.10';

    return PopScope(
      canPop: !_isLoading, // Block back button while claiming
      child: Directionality(
        textDirection: widget.isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.timer, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.isAr ? 'تأكيد إكمال المهمة' : 'Confirm Task Completion',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (!_canClaim) ...[
                Text(
                  widget.isAr
                      ? 'يرجى الانتظار في الصفحة لمدة $_secondsRemaining ثانية للتحقق...'
                      : 'Please wait on the page for $_secondsRemaining seconds to verify...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: 1 - (_secondsRemaining / (widget.task['cooldown_seconds'] as int? ?? 15)),
                    backgroundColor: AppColors.cardBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeWidth: 5,
                  ),
                ),
              ] else ...[
                const Icon(Icons.check_circle, color: AppColors.accent, size: 50),
                const SizedBox(height: 12),
                Text(
                  widget.isAr
                      ? 'مستعد للحصول على المكافأة بقيمة $reward Coinz!'
                      : 'Ready to receive the reward of $reward Coinz!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(
                widget.isAr ? 'إلغاء' : 'Cancel',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: (_canClaim && !_isLoading) ? _claimReward : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.cardBorder,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      widget.isAr ? 'استلام المكافأة' : 'Claim Reward',
                      style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
