import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import '../home/home_controller.dart';
import 'ads_controller.dart';

class AdsScreen extends StatefulWidget {
  final bool hideAppBar;
  const AdsScreen({super.key, this.hideAppBar = false});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdsController>().loadHistory();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ads = context.watch<AdsController>();
    final home = context.watch<HomeController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: const Text('مشاهدة الإعلانات'),
              backgroundColor: AppColors.background,
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // ── Watch Ad Button ──
              _buildWatchButton(ads, home),

              const SizedBox(height: 28),

              // ── How it works ──
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 كيف يعمل النظام',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow(Icons.timer_outlined, 'مدة الانتظار 30 ثانية بين الإعلانات'),
                    _infoRow(Icons.workspace_premium_outlined, 'أعضاء VIP يحصلون على مضاعف حتى 2.2x'),
                    _infoRow(Icons.verified_outlined, 'تُضاف المكاسب فوراً للمحفظة'),
                    _infoRow(Icons.security_outlined, 'النظام محمي بـ Ledger مزدوج'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Ad History ──
              if (ads.history.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'آخر الإعلانات المشاهدة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ...ads.history.take(5).map((h) => _historyItem(h)),
              ],

              if (ads.historyLoading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWatchButton(AdsController ads, HomeController home) {
    final isWatching = ads.state == AdWatchState.watching;
    final isCooldown = ads.state == AdWatchState.cooldown;
    final isSuccess = ads.state == AdWatchState.success;
    final isError = ads.state == AdWatchState.error;

    final List<Map<String, dynamic>> providers = [
      {
        'id': 'admob',
        'name': 'Google AdMob',
        'desc': 'إعلانات جوجل الرسمية عالية الأداء',
        'icon': Icons.ads_click_outlined,
        'badge': 'مستحسن',
        'gradient': [AppColors.primary, const Color(0xFF0080FF)],
      },
      {
        'id': 'meta',
        'name': 'Meta Audience',
        'desc': 'إعلانات فيسبوك المستهدفة ذات القيمة العالية',
        'icon': Icons.facebook_outlined,
        'badge': 'مدعوم',
        'gradient': [const Color(0xFF1877F2), const Color(0xFF8B5CF6)],
      },
      {
        'id': 'unity',
        'name': 'Unity Ads',
        'desc': 'فيديوهات ألعاب تفاعلية ومسلية',
        'icon': Icons.games_outlined,
        'badge': 'نشط',
        'gradient': [const Color(0xFF00F2FE), const Color(0xFF4FACFE)],
      },
      {
        'id': 'startio',
        'name': 'Start.io',
        'desc': 'إعلانات محلية ذكية وسريعة التحميل',
        'icon': Icons.star_outline_rounded,
        'badge': 'نشط',
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      },
    ];

    return Column(
      children: [
        // 1. Status Display Card
        GlassCard(
          borderColor: isSuccess
              ? AppColors.accent.withOpacity(0.4)
              : isError
                  ? AppColors.error.withOpacity(0.4)
                  : isCooldown
                      ? AppColors.warning.withOpacity(0.4)
                      : AppColors.primary.withOpacity(0.3),
          child: Column(
            children: [
              ScaleTransition(
                scale: (!isCooldown && !isWatching)
                    ? _pulseAnim
                    : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isSuccess
                          ? [AppColors.accent.withOpacity(0.3), Colors.transparent]
                          : isError
                              ? [AppColors.error.withOpacity(0.3), Colors.transparent]
                              : isCooldown
                                  ? [AppColors.warning.withOpacity(0.3), Colors.transparent]
                                  : [AppColors.primary.withOpacity(0.25), Colors.transparent],
                    ),
                    border: Border.all(
                      color: isSuccess
                          ? AppColors.accent
                          : isError
                              ? AppColors.error
                              : isCooldown
                                  ? AppColors.warning
                                  : AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: isCooldown
                      ? Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 70,
                                height: 70,
                                child: CircularProgressIndicator(
                                  value: 1 - (ads.cooldownSeconds / 30),
                                  color: AppColors.warning,
                                  backgroundColor: AppColors.warning.withOpacity(0.2),
                                  strokeWidth: 4,
                                ),
                              ),
                              Text(
                                '${ads.cooldownSeconds}s',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        )
                      : isWatching
                          ? const Center(
                              child: SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 3,
                                ),
                              ),
                            )
                          : Icon(
                              isSuccess
                                  ? Icons.check_circle_outline
                                  : isError
                                      ? Icons.error_outline
                                      : Icons.play_circle_fill,
                              size: 50,
                              color: isSuccess
                                  ? AppColors.accent
                                  : isError
                                      ? AppColors.error
                                      : AppColors.primary,
                            ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isCooldown
                    ? 'انتظر قبل الإعلان التالي'
                    : isWatching
                        ? 'جارٍ تحميل وتشغيل الإعلان...'
                        : isSuccess
                            ? '✅ تمت المشاهدة بنجاح! تم شحن محفظتك'
                            : isError
                                ? (ads.errorMessage ?? 'حدث خطأ في تحميل الإعلان')
                                : 'جاهز للتشغيل - اختر شبكة إعلانات في الأسفل',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCooldown
                      ? AppColors.warning
                      : isSuccess
                          ? AppColors.accent
                          : isError
                              ? AppColors.error
                              : AppColors.textPrimary,
                ),
              ),
              if (isError) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: ads.resetError,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    foregroundColor: AppColors.error,
                    minimumSize: const Size(120, 36),
                  ),
                  child: const Text('إعادة محاولة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 2. Ad Networks Provider List Header
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'شبكات الإعلانات المتوفرة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 3. Render Provider Cards
        ...providers.map((p) {
          final isEnabled = !isWatching && !isCooldown;
          final pGradient = p['gradient'] as List<Color>;

          return Opacity(
            opacity: isEnabled ? 1.0 : 0.5,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                borderColor: AppColors.cardBorder,
                child: Row(
                  children: [
                    // Network Icon with custom gradient circle
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: pGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(p['icon'], color: Colors.black, size: 26),
                    ),
                    const SizedBox(width: 14),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                p['name'],
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: pGradient[0].withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: pGradient[0].withOpacity(0.4), width: 0.5),
                                ),
                                child: Text(
                                  p['badge'],
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: pGradient[0],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p['desc'],
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Play Button
                    ElevatedButton(
                      onPressed: isEnabled
                          ? () {
                              ads.watchAd(
                                provider: p['id'],
                                onBalanceRefreshNeeded: () => home.refreshDashboard(),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pGradient[0],
                        disabledBackgroundColor: Colors.grey.withOpacity(0.2),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'شاهد',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyItem(Map<String, dynamic> h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_outline, color: AppColors.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              h['created_at']?.toString().substring(0, 10) ?? '',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            '+\$${double.tryParse(h['reward_amount']?.toString() ?? '0')?.toStringAsFixed(4) ?? '0.0000'}',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
