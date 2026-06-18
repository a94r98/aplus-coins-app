import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/vip_badge.dart';
import '../home/home_controller.dart';
import '../auth/auth_controller.dart';
import '../../core/api/api_service.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/currency_formatter.dart';

class VipScreen extends StatefulWidget {
  const VipScreen({super.key});

  @override
  State<VipScreen> createState() => _VipScreenState();
}

class _VipScreenState extends State<VipScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _claimStatus;
  bool _isClaimStatusLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchClaimStatus();
    });
  }

  Future<void> _fetchClaimStatus() async {
    final home = context.read<HomeController>();
    final currentTier = home.dashboard?.vipTier ?? 'FREE';
    if (currentTier == 'FREE') {
      if (mounted) {
        setState(() {
          _claimStatus = null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isClaimStatusLoading = true;
      });
    }

    try {
      final res = await _apiService.get(Endpoints.dailyVipRewardStatus);
      if (res['status'] == 'success' && res.containsKey('data')) {
        if (mounted) {
          setState(() {
            _claimStatus = res['data'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching VIP daily claim status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isClaimStatusLoading = false;
        });
      }
    }
  }

  Future<void> _claimDailyVipReward(bool isAr) async {
    if (_claimStatus == null) return;
    
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final String idempotencyKey = 'vip_claim_${DateTime.now().millisecondsSinceEpoch}_${_claimStatus!['subscriptionId']}';
      final res = await _apiService.post(
        Endpoints.claimDailyVipReward,
        idempotencyKey: idempotencyKey,
      );

      if (res['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAr
                  ? 'تم استلام المكافأة اليومية بنجاح!'
                  : 'Daily VIP reward claimed successfully!'),
              backgroundColor: AppColors.accent,
            ),
          );
        }
        await _fetchClaimStatus();
        if (mounted) {
          await context.read<HomeController>().refreshDashboard();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? (isAr ? 'فشلت عملية المطالبة' : 'Claim failed')),
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

  Color _getTierColor(String tier) {
    switch (tier.toUpperCase()) {
      case 'VIP1':
        return AppColors.vip1;
      case 'VIP2':
        return AppColors.vip2;
      case 'VIP3':
        return AppColors.vip3;
      case 'VIP4':
        return const Color(0xFFEC4899);
      case 'VIP5':
        return const Color(0xFFEF4444);
      case 'VIP6':
        return const Color(0xFF10B981);
      case 'VIP7':
        return const Color(0xFF06B6D4);
      case 'VIP8':
        return const Color(0xFFF97316);
      case 'VIP9':
        return const Color(0xFF84CC16);
      case 'VIP10':
        return const Color(0xFF6366F1);
      default:
        return AppColors.primary;
    }
  }

  Widget _buildDailyClaimCard(bool isAr, String country) {
    if (_claimStatus == null) return const SizedBox();

    final tier = _claimStatus!['tier']?.toString() ?? 'VIP1';
    final tierColor = _getTierColor(tier);
    final dailyReward = double.tryParse(_claimStatus!['dailyRewardAmount']?.toString() ?? '0') ?? 0.0;
    final isClaimedToday = _claimStatus!['isClaimedToday'] as bool? ?? false;
    final daysRemaining = _claimStatus!['daysRemaining'] as int? ?? 0;
    final daysTotal = _claimStatus!['daysTotal'] as int? ?? 30;

    return GlassCard(
      borderColor: tierColor.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars, color: tierColor, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr ? 'عائد VIP اليومي ($tier)' : 'Daily VIP Reward ($tier)',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: tierColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isClaimedToday ? AppColors.accent.withOpacity(0.2) : tierColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isClaimedToday
                      ? (isAr ? 'تم الاستلام' : 'Claimed')
                      : (isAr ? 'جاهز للمطالبة' : 'Ready'),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isClaimedToday ? AppColors.accent : tierColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'مكافأة اليوم' : "Today's Reward",
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(dailyReward, country, isAr),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isAr ? 'المدة المتبقية' : 'Remaining Days',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAr ? '$daysRemaining من $daysTotal يوم' : '$daysRemaining of $daysTotal days',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: daysTotal > 0 ? daysRemaining / daysTotal : 0.0,
              backgroundColor: AppColors.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(tierColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 18),
          if (isClaimedToday)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'لقد استلمت دفعتك لهذا اليوم بنجاح. عد غداً للمطالبة بمكأفاتك.'
                          : "You've successfully claimed today's reward. Come back tomorrow!",
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            GradientButton(
              text: isAr ? 'استلام مكافأة اليوم' : 'Claim Today\'s Reward',
              colors: [tierColor, tierColor.withOpacity(0.8)],
              onPressed: () => _claimDailyVipReward(isAr),
            ),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> _tiers = [
    {
      'id': 'VIP1',
      'name': 'VIP Level 1',
      'arabicName': 'عضوية VIP 1',
      'cost': 50.0,
      'dailyLimit': '10 إعلانات',
      'dailyLimitEn': '10 Ads/day',
      'reward': 1.66,
      'multiplier': '1.05x',
      'color': AppColors.vip1,
      'icon': Icons.star_border,
      'features': [
        'أرباح مضاعفة 1.05x مقارنة بالفئة المجانية',
        'الحد اليومي للإعلانات: 10 إعلانات',
        'معدل سقف يومي: 2 دولار يومياً',
        'الاسترداد اليومي التلقائي للعضوية',
      ],
      'featuresEn': [
        '1.05x reward multiplier compared to Free tier',
        'Daily ad limit: 10 ads',
        'Daily earning cap: \$2.00',
        'Automatic VIP daily claim benefits',
      ],
    },
    {
      'id': 'VIP2',
      'name': 'VIP Level 2',
      'arabicName': 'عضوية VIP 2',
      'cost': 100.0,
      'dailyLimit': '20 إعلان',
      'dailyLimitEn': '20 Ads/day',
      'reward': 3.33,
      'multiplier': '1.10x',
      'color': AppColors.vip2,
      'icon': Icons.stars_sharp,
      'features': [
        'أرباح مضاعفة 1.10x مقارنة بالفئة المجانية',
        'الحد اليومي للإعلانات: 20 إعلان',
        'معدل سقف يومي: 3 دولار يومياً',
        'الاسترداد اليومي التلقائي للعضوية',
      ],
      'featuresEn': [
        '1.10x reward multiplier compared to Free tier',
        'Daily ad limit: 20 ads',
        'Daily earning cap: \$3.00',
        'Automatic VIP daily claim benefits',
      ],
    },
    {
      'id': 'VIP3',
      'name': 'VIP Level 3',
      'arabicName': 'عضوية VIP 3',
      'cost': 250.0,
      'dailyLimit': '30 إعلان',
      'dailyLimitEn': '30 Ads/day',
      'reward': 8.33,
      'multiplier': '1.15x',
      'color': AppColors.vip3,
      'icon': Icons.workspace_premium,
      'features': [
        'أرباح مضاعفة 1.15x مقارنة بالفئة المجانية',
        'الحد اليومي للإعلانات: 30 إعلان',
        'معدل سقف يومي: 5 دولار يومياً',
        'الاسترداد اليومي التلقائي للعضوية',
      ],
      'featuresEn': [
        '1.15x reward multiplier compared to Free tier',
        'Daily ad limit: 30 ads',
        'Daily earning cap: \$5.00',
        'Automatic VIP daily claim benefits',
      ],
    },
    {
      'id': 'VIP4',
      'name': 'VIP Level 4',
      'arabicName': 'عضوية VIP 4',
      'cost': 500.0,
      'dailyLimit': '60 إعلان',
      'dailyLimitEn': '60 Ads/day',
      'reward': 16.66,
      'multiplier': '1.20x',
      'color': const Color(0xFFEC4899),
      'icon': Icons.flash_on,
      'features': [
        'أرباح مضاعفة 1.20x مقارنة بالفئة المجانية',
        'الحد اليومي للإعلانات: 60 إعلان',
        'معدل سقف يومي: 7 دولار يومياً',
        'دعم فني فوري مخصص للأعضاء',
      ],
      'featuresEn': [
        '1.20x reward multiplier compared to Free tier',
        'Daily ad limit: 60 ads',
        'Daily earning cap: \$7.00',
        'Priority premium support chat',
      ],
    },
    {
      'id': 'VIP5',
      'name': 'VIP Level 5',
      'arabicName': 'عضوية VIP 5',
      'cost': 1000.0,
      'dailyLimit': '80 إعلان',
      'dailyLimitEn': '80 Ads/day',
      'reward': 33.33,
      'multiplier': '1.30x',
      'color': const Color(0xFFEF4444),
      'icon': Icons.local_fire_department,
      'features': [
        'أرباح مضاعفة 1.30x مقارنة بالفئة المجانية',
        'الحد اليومي للإعلانات: 80 إعلان',
        'معدل سقف يومي: 10 دولار يومياً',
        'أولوية ممتازة في جميع العمليات',
      ],
      'featuresEn': [
        '1.30x reward multiplier compared to Free tier',
        'Daily ad limit: 80 ads',
        'Daily earning cap: \$10.00',
        'Priority processing on all orders',
      ],
    },
    {
      'id': 'VIP6',
      'name': 'VIP Level 6',
      'arabicName': 'عضوية VIP 6',
      'cost': 2000.0,
      'dailyLimit': '100 إعلان',
      'dailyLimitEn': '100 Ads/day',
      'reward': 66.66,
      'multiplier': '1.40x',
      'color': const Color(0xFF10B981),
      'icon': Icons.rocket_launch,
      'features': [
        'أرباح مضاعفة 1.40x مقارنة بالفئة المجانية',
        'الحد اليومي للإعلانات: 100 إعلان',
        'معدل سقف يومي: 15 دولار يومياً',
        'أولوية معالجة فورية فائقة السرعة',
      ],
      'featuresEn': [
        '1.40x reward multiplier compared to Free tier',
        'Daily ad limit: 100 ads',
        'Daily earning cap: \$15.00',
        'Super fast instant processing priority',
      ],
    },
    {
      'id': 'VIP7',
      'name': 'VIP Level 7',
      'arabicName': 'عضوية VIP 7',
      'cost': 3000.0,
      'dailyLimit': '120 إعلان',
      'dailyLimitEn': '120 Ads/day',
      'reward': 100.0,
      'multiplier': '1.50x',
      'color': const Color(0xFF06B6D4),
      'icon': Icons.bolt,
      'features': [
        'أرباح مضاعفة 1.50x مقارنة بالفئة المجانية',
        'الحد اليومي للإعلانات: 120 إعلان',
        'معدل سقف يومي: 20 دولار يومياً',
        'أيقونة شارة ذهبية متوهجة مخصصة للملف',
      ],
      'featuresEn': [
        '1.50x reward multiplier compared to Free tier',
        'Daily ad limit: 120 ads',
        'Daily earning cap: \$20.00',
        'Custom glowing badge in profile header',
      ],
    },
    {
      'id': 'VIP8',
      'name': 'VIP Level 8',
      'arabicName': 'عضوية VIP 8',
      'cost': 5000.0,
      'dailyLimit': '140 إعلان',
      'dailyLimitEn': '140 Ads/day',
      'reward': 166.66,
      'multiplier': '1.60x',
      'color': const Color(0xFFF97316),
      'icon': Icons.shield,
      'features': [
        'أرباح مضاعفة 1.60x مقارنة بالفئة المجانية',
        'الحد اليومي للإعلانات: 140 إعلان',
        'معدل سقف يومي: 30 دولار يومياً',
        'تأمين كامل ضد تجميد الحساب التلقائي',
      ],
      'featuresEn': [
        '1.60x reward multiplier compared to Free tier',
        'Daily ad limit: 140 ads',
        'Daily earning cap: \$30.00',
        'Complete bypass protection on automated limits',
      ],
    },
    {
      'id': 'VIP9',
      'name': 'VIP Level 9',
      'arabicName': 'عضوية VIP 9',
      'cost': 7500.0,
      'dailyLimit': '160 إعلان',
      'dailyLimitEn': '160 Ads/day',
      'reward': 250.0,
      'multiplier': '1.80x',
      'color': const Color(0xFF84CC16),
      'icon': Icons.emoji_events,
      'features': [
        'أرباح مضاعفة 1.80x مقارنة بالفئة المجانية',
        'الحد اليومي للإعلانات: 160 إعلان',
        'معدل سقف يومي: 40 دولار يومياً',
        'دعم فني خاص على الواتساب 24/7',
      ],
      'featuresEn': [
        '1.80x reward multiplier compared to Free tier',
        'Daily ad limit: 160 ads',
        'Daily earning cap: \$40.00',
        'Direct WhatsApp support channel 24/7',
      ],
    },
    {
      'id': 'VIP10',
      'name': 'VIP Level 10',
      'arabicName': 'عضوية VIP 10',
      'cost': 10000.0,
      'dailyLimit': '200 إعلان',
      'dailyLimitEn': '200 Ads/day',
      'reward': 333.33,
      'multiplier': '2.00x',
      'color': const Color(0xFF6366F1),
      'icon': Icons.auto_awesome,
      'features': [
        'أرباح مضاعفة 2.00x - أعلى مضاعف بالكامل',
        'الحد اليومي للإعلانات: 200 إعلان',
        'معدل سقف يومي: 50 دولار يومياً',
        'عضوية VIP الملكية كاملة المزايا الحصرية',
      ],
      'featuresEn': [
        'Maximum 2.00x reward multiplier',
        'Daily ad limit: 200 ads',
        'Daily earning cap: \$50.00',
        'Royal VIP tier status with complete privileges',
      ],
    },
  ];

  Future<void> _upgradeTier(String tierId, double cost, bool isAr) async {
    final home = context.read<HomeController>();
    if (home.dashboard == null) return;

    if (home.dashboard!.availableBalance < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr
              ? 'عذراً، رصيدك المتاح الحالي لا يكفي لإتمام هذه الترقية.'
              : 'Sorry, your available balance is insufficient for this upgrade.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(isAr ? 'تأكيد الترقية' : 'Confirm Upgrade'),
          content: Text(isAr
              ? 'هل أنت متأكد من رغبتك في شراء ترقية $tierId بقيمة ${CurrencyFormatter.format(cost, home.dashboard!.country, isAr)}؟ سيتم خصم المبلغ من رصيدك المتاح.'
              : 'Are you sure you want to purchase $tierId upgrade for ${CurrencyFormatter.format(cost, home.dashboard!.country, false)}? This will be deducted from your available balance.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(isAr ? 'شراء' : 'Purchase', style: const TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await _apiService.post(Endpoints.upgradeVip, body: {'tier': tierId});
      if (res['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAr
                  ? 'تمت الترقية بنجاح إلى $tierId!'
                  : 'Successfully upgraded to $tierId!'),
              backgroundColor: AppColors.accent,
            ),
          );
        }
        await home.refreshDashboard();
        await _fetchClaimStatus();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? (isAr ? 'فشلت عملية الترقية' : 'Upgrade failed')),
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
    final home = context.watch<HomeController>();
    final auth = context.watch<AuthController>();
    final isAr = !auth.isEnglish;
    final currentTier = home.dashboard?.vipTier ?? 'FREE';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isAr ? 'ترقية فئة VIP' : 'VIP Tiers'),
        backgroundColor: AppColors.background,
        leading: Navigator.canPop(context) ? null : const SizedBox(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Tier Status Header
              GlassCard(
                borderColor: AppColors.primary.withOpacity(0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'فئتك الحالية هي:' : 'Your current tier is:',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentTier,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    VipBadge(tier: currentTier, fontSize: 16),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (currentTier.toUpperCase() != 'FREE') ...[
                if (_isClaimStatusLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (_claimStatus != null && _claimStatus!['hasActiveVip'] == true) ...[
                  _buildDailyClaimCard(isAr, home.dashboard?.country ?? ''),
                  const SizedBox(height: 24),
                ],
              ],

              Text(
                isAr ? 'فئات العضوية الممتازة المتاحة' : 'Available Premium VIP Tiers',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),

              if (!_isLoading)
                ..._tiers.map((t) {
                  final isCurrent = currentTier.toUpperCase() == t['id'].toString().toUpperCase();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: GlassCard(
                      borderColor: isCurrent
                          ? t['color'].withOpacity(0.8)
                          : AppColors.cardBorder,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(t['icon'], color: t['color'], size: 28),
                                  const SizedBox(width: 12),
                                  Text(
                                    isAr ? t['arabicName'] : t['name'],
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: t['color'],
                                    ),
                                  ),
                                ],
                              ),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: t['color'].withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isAr ? 'مفعلة' : 'Active',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: t['color'],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _statCol(isAr ? 'التكلفة' : 'Cost', CurrencyFormatter.format(t['cost'] as double, home.dashboard?.country ?? '', isAr), isAr),
                              _statCol(isAr ? 'الحد اليومي' : 'Ad Limit', isAr ? t['dailyLimit'] : t['dailyLimitEn'], isAr),
                              _statCol(isAr ? 'عائد الإعلان' : 'Per Ad', CurrencyFormatter.format(t['reward'] as double, home.dashboard?.country ?? '', isAr), isAr),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.cardBorder),
                          const SizedBox(height: 12),
                          ...List.generate(
                            t[isAr ? 'features' : 'featuresEn'].length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Icon(Icons.check, color: t['color'], size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      t[isAr ? 'features' : 'featuresEn'][index],
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!isCurrent)
                            GradientButton(
                              text: isAr ? 'ترقية الآن' : 'Upgrade Now',
                              colors: [t['color'], t['color'].withOpacity(0.8)],
                              onPressed: () => _upgradeTier(t['id'], t['cost'] as double, isAr),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCol(String label, String val, bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          val,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
