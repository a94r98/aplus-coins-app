import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/api/api_service.dart';
import '../../core/api/endpoints.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/vip_badge.dart';
import '../auth/auth_controller.dart';
import 'home_controller.dart';
import '../wallet/wallet_screen.dart';
import '../vip/vip_screen.dart';
import '../../core/utils/currency_formatter.dart';

class ReferralTab extends StatefulWidget {
  const ReferralTab({super.key});

  @override
  State<ReferralTab> createState() => _ReferralTabState();
}

class _ReferralTabState extends State<ReferralTab> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  String? _error;
  
  // Filter variables
  int _selectedLevelFilter = 0; // 0 = All, 1 = Lvl 1, 2 = Lvl 2, 3 = Lvl 3
  String _searchQuery = '';
  bool _isRulesExpanded = false;
  
  Map<String, dynamic> _summary = {
    'level1': 0,
    'level2': 0,
    'level3': 0,
    'total_commissions': 0.0
  };
  List<dynamic> _referrals = [];
  List<dynamic> _filteredReferrals = [];

  @override
  void initState() {
    super.initState();
    _loadReferralData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _applyFilters();
    });
  }

  Future<void> _loadReferralData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _apiService.get(Endpoints.referrals);
      if (res['status'] == 'success' && res['data'] != null) {
        final data = res['data'];
        if (mounted) {
          setState(() {
            if (data['summary'] != null) {
              _summary = {
                'level1': data['summary']['level1'] ?? 0,
                'level2': data['summary']['level2'] ?? 0,
                'level3': data['summary']['level3'] ?? 0,
                'total_commissions': double.tryParse(data['summary']['total_commissions']?.toString() ?? '0') ?? 0.0,
              };
            }
            _referrals = data['referrals'] ?? [];
            _applyFilters();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<dynamic> temp = List.from(_referrals);
    
    // Level Filter
    if (_selectedLevelFilter > 0) {
      temp = temp.where((ref) => ref['level'] == _selectedLevelFilter).toList();
    }
    
    // Search Filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      temp = temp.where((ref) {
        final username = (ref['username'] ?? '').toString().toLowerCase();
        final email = (ref['email'] ?? '').toString().toLowerCase();
        return username.contains(query) || email.contains(query);
      }).toList();
    }
    
    _filteredReferrals = temp;
  }

  void _shareViaWhatsApp(String code, bool isAr) async {
    final message = isAr
        ? 'أهلاً بك! انضم إلي في تطبيق A Plus Coins الرائع وشاهد الإعلانات لتربح العملات والجوائز الحقيقية. استعمل رمز الإحالة الخاص بي ($code) عند التسجيل لنحصل على مكافآت إضافية:\nرابط التطبيق: https://apluscoins.com'
        : 'Hey! Join me on the amazing A Plus Coins app, watch ads and earn real rewards. Use my referral code ($code) on signup for extra bonus rewards:\nDownload: https://apluscoins.com';
    
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تعذر فتح الواتساب' : 'Could not launch WhatsApp'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _shareViaTelegram(String code, bool isAr) async {
    final message = isAr
        ? 'أهلاً بك! انضم إلي في تطبيق A Plus Coins لربح المكافآت بمشاهدة الإعلانات. استعمل كودي ($code) للتسجيل والبدء بالربح:\nhttps://apluscoins.com'
        : 'Hey! Join me on A Plus Coins to earn rewards by watching simple ads. Use my referral code ($code) to register and start earning:\nhttps://apluscoins.com';
    
    final url = 'https://t.me/share/url?url=https://apluscoins.com&text=${Uri.encodeComponent(message)}';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch Telegram sharing link';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تعذر فتح التيليجرام' : 'Could not launch Telegram'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _copyInviteText(String code, bool isAr) {
    final message = isAr
        ? 'حمل تطبيق A Plus Coins الآن وسجل باستخدام كود الإحالة الخاص بي ($code) لتربح الكونزات المجانية فوراً! مشاهدة الإعلانات البسيطة تكسبك جوائز حقيقية يومياً.\nتحميل التطبيق: https://apluscoins.com'
        : 'Download A Plus Coins app now and register using my referral code ($code) to earn free Coinz instantly! Watch simple ads and secure real daily payouts.\nApp Link: https://apluscoins.com';
        
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAr ? 'تم نسخ نص الدعوة المنسق!' : 'Inviting message copied!'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  void _showReferralDetailSheet(Map<String, dynamic> ref, bool isAr) {
    final username = ref['username'] ?? 'User';
    final email = ref['email'] ?? '---';
    final vipTier = ref['vip_tier'] ?? 'FREE';
    final int level = ref['level'] ?? 1;
    final double commission = double.tryParse(ref['commission_earned']?.toString() ?? '0') ?? 0.0;
    
    String dateStr = '---';
    if (ref['created_at'] != null) {
      try {
        final parsedDate = DateTime.parse(ref['created_at'].toString()).toLocal();
        dateStr = DateFormat('yyyy/MM/dd hh:mm a').format(parsedDate);
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            border: Border(
              top: BorderSide(color: AppColors.cardBorder, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            VipBadge(tier: vipTier, fontSize: 10),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isAr ? 'مستوى $level' : 'Lvl $level',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: AppColors.cardBorder),
              const SizedBox(height: 12),
              
              _buildDetailRow(
                isAr ? 'البريد الإلكتروني' : 'Email Address', 
                email, 
                Icons.email_outlined
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                isAr ? 'تاريخ الانضمام' : 'Join Date', 
                dateStr, 
                Icons.calendar_month_outlined
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                isAr ? 'عمولة الأرباح المقدمة' : 'Commissions Contributed', 
                CurrencyFormatter.format(commission, context.read<HomeController>().dashboard?.country ?? '', isAr), 
                Icons.monetization_on_outlined,
                valueColor: AppColors.accent,
                boldValue: true
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    isAr ? 'إغلاق' : 'Close',
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor, bool boldValue = false}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: boldValue ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final auth = context.watch<AuthController>();
    final isAr = !auth.isEnglish;

    final referralCode = home.dashboard?.referralCode ?? '---';
    final userVip = home.dashboard?.vipTier ?? 'FREE';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isAr ? 'برنامج الإحالة' : 'Referral Program',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const SizedBox(),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppColors.primary),
            onPressed: () {
              setState(() {
                _isRulesExpanded = !_isRulesExpanded;
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReferralData,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Metallic Gradient Invitation Card ──
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.6),
                      const Color(0xFF005A80),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: GlassCard(
                  padding: const EdgeInsets.all(22),
                  borderColor: Colors.white.withOpacity(0.15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.stars_rounded, color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                isAr ? 'بطاقة دعوة VIP' : 'VIP INVITATION',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              userVip,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isAr ? 'رمز الإحالة الخاص بك' : 'YOUR REFERRAL CODE',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SelectableText(
                            referralCode,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 3.0,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: referralCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isAr ? 'تم نسخ الرمز!' : 'Code copied!'),
                                  backgroundColor: AppColors.accent,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.copy_rounded, color: AppColors.primary, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    isAr ? 'نسخ' : 'Copy',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 12),
                      Text(
                        isAr ? 'مشاركة سريعة عبر:' : 'Quick Share Via:',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _shareViaWhatsApp(referralCode, isAr),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white38),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                              label: const Text('WhatsApp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _shareViaTelegram(referralCode, isAr),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white38),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.telegram_rounded, size: 16),
                              label: const Text('Telegram', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _copyInviteText(referralCode, isAr),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white12,
                              padding: const EdgeInsets.all(10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── 2. Accordion/Timeline of referral rules ──
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  child: GlassCard(
                    borderColor: AppColors.primary.withOpacity(0.2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'قواعد ونظام العمولات التراكمي' : 'Decaying Multi-Level Commission Rules',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isAr 
                              ? 'سجل أصدقاءك واحصل على مكافأة فورية بالإضافة لنسبة من عمولات إعلاناتهم مدى الحياة. تقل النسبة تدريجياً بمرور الوقت لضمان استقرار اقتصاد العملات:'
                              : 'Invite friends and get an instant signup bonus plus commissions from their ad watch rewards forever. Rates decay over time to balance the coin economy:',
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        _buildRulesTimelineItem(
                          isAr ? 'أول 30 يوم انضمام (العمولة القصوى)' : 'First 30 days of join (Maximum rewards)',
                          isAr ? 'مستوى 1: 10% | مستوى 2: 5% | مستوى 3: 2%' : 'Lvl 1: 10% | Lvl 2: 5% | Lvl 3: 2%',
                          Colors.green,
                          true
                        ),
                        _buildRulesTimelineItem(
                          isAr ? 'من 31 إلى 90 يوم' : 'From 31 to 90 days',
                          isAr ? 'مستوى 1: 5% | مستوى 2: 2.5% | مستوى 3: 1%' : 'Lvl 1: 5% | Lvl 2: 2.5% | Lvl 3: 1%',
                          Colors.blue,
                          false
                        ),
                        _buildRulesTimelineItem(
                          isAr ? 'من 91 إلى 180 يوم' : 'From 91 to 180 days',
                          isAr ? 'مستوى 1: 2% | مستوى 2: 1% | مستوى 3: 0.5%' : 'Lvl 1: 2% | Lvl 2: 1% | Lvl 3: 0.5%',
                          Colors.orange,
                          false
                        ),
                        _buildRulesTimelineItem(
                          isAr ? 'أكثر من 180 يوم' : 'More than 180 days',
                          isAr ? 'مستوى 1: 1% | مستوى 2: 0.5% | مستوى 3: 0.1%' : 'Lvl 1: 1% | Lvl 2: 0.5% | Lvl 3: 0.1%',
                          Colors.red,
                          false
                        ),
                        const SizedBox(height: 6),
                        const Divider(color: AppColors.cardBorder),
                        const SizedBox(height: 6),
                        Text(
                          isAr 
                              ? '💡 تلميح: نسبة الترقية (VIP) للداعي تزيد من قيمة مكافأة التسجيل الفورية تلقائياً!'
                              : '💡 Tip: Referrer\'s VIP multiplier increases the signup bonus reward automatically!',
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.vip3, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                crossFadeState: _isRulesExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),

              // ── 3. Interactive Downline Level Stats ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'شبكة الإحالة والشركاء' : 'Referral Network & Downlines',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedLevelFilter = 0;
                        _applyFilters();
                      });
                    },
                    child: Text(
                      isAr ? 'عرض الكل' : 'Show All',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInteractiveStatBox(
                      label: isAr ? 'مستوى 1' : 'Level 1', 
                      value: _summary['level1'].toString(), 
                      color: Colors.blue, 
                      icon: Icons.person_outline, 
                      filterValue: 1
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInteractiveStatBox(
                      label: isAr ? 'مستوى 2' : 'Level 2', 
                      value: _summary['level2'].toString(), 
                      color: Colors.purple, 
                      icon: Icons.people_outline, 
                      filterValue: 2
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInteractiveStatBox(
                      label: isAr ? 'مستوى 3' : 'Level 3', 
                      value: _summary['level3'].toString(), 
                      color: Colors.orange, 
                      icon: Icons.group_work_outlined, 
                      filterValue: 3
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // ── 4. Earnings & VIP Upgrade Promotion Box ──
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WalletScreen()),
                  );
                },
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'إجمالي عمولات الإحالة' : 'Total Referral Earnings',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAr ? 'انقر لفتح المحفظة والتفاصيل' : 'Tap to open wallet details',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 9.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        CurrencyFormatter.format(_summary['total_commissions'] as double, home.dashboard?.country ?? '', isAr),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              // VIP Promo upgrade box
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                borderColor: AppColors.vip3.withOpacity(0.15),
                child: Row(
                  children: [
                    const Icon(Icons.star_purple500_rounded, color: AppColors.vip3, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'ضاعف أرباح وعمولات دعوتك بالترقية حتى VIP 10'
                            : 'Boost invite rewards & commissions up to VIP 10',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VipScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.vip3,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        isAr ? 'ترقية' : 'Upgrade',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── 5. Search Bar & Level List Filter Chips ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'الأعضاء المسجلون' : 'Referred List',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      '${_filteredReferrals.length} / ${_referrals.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Custom Search field
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo', fontSize: 13),
                  decoration: InputDecoration(
                    hintText: isAr ? 'ابحث عن اسم مستخدم أو بريد إلكتروني...' : 'Search username or email...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Horizonal filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(isAr ? 'الكل' : 'All', 0),
                    const SizedBox(width: 8),
                    _buildFilterChip(isAr ? 'مستوى 1' : 'Level 1', 1),
                    const SizedBox(width: 8),
                    _buildFilterChip(isAr ? 'مستوى 2' : 'Level 2', 2),
                    const SizedBox(width: 8),
                    _buildFilterChip(isAr ? 'مستوى 3' : 'Level 3', 3),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── 6. Referred Users list ──
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Text(
                          isAr ? 'حدث خطأ أثناء تحميل البيانات' : 'Error loading referrals',
                          style: const TextStyle(color: AppColors.error, fontFamily: 'Cairo'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadReferralData,
                          child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filteredReferrals.isEmpty)
                GlassCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline_rounded, size: 48, color: AppColors.primary.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text(
                            isAr ? 'لا يوجد أعضاء يطابقون الفلتر' : 'No users match criteria',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr 
                                ? 'شارك رمز الإحالة الخاص بك وابدأ ببناء شبكتك الآن' 
                                : 'Share your invitation code to start growing your list',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredReferrals.length,
                  itemBuilder: (context, index) {
                    final ref = _filteredReferrals[index];
                    final String username = ref['username'] ?? 'User';
                    final String email = ref['email'] ?? '';
                    final String vipTier = ref['vip_tier'] ?? 'FREE';
                    final int level = ref['level'] ?? 1;
                    final double commission = double.tryParse(ref['commission_earned']?.toString() ?? '0') ?? 0.0;

                    Color levelColor;
                    if (level == 1) {
                      levelColor = Colors.blue;
                    } else if (level == 2) {
                      levelColor = Colors.purple;
                    } else {
                      levelColor = Colors.orange;
                    }
                    
                    // Determine VIP avatar ring colors
                    List<Color> avatarGradient = [AppColors.surface, AppColors.surface];
                    if (vipTier != 'FREE') {
                      if (vipTier.startsWith('VIP1') || vipTier.startsWith('VIP2')) {
                        avatarGradient = [AppColors.primary, AppColors.primary.withOpacity(0.5)];
                      } else if (vipTier.startsWith('VIP3') || vipTier.startsWith('VIP4')) {
                        avatarGradient = [AppColors.vip3, AppColors.vip3.withOpacity(0.5)];
                      } else {
                        avatarGradient = [Colors.amber, Colors.orange];
                      }
                    }
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => _showReferralDetailSheet(ref, isAr),
                        borderRadius: BorderRadius.circular(16),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          borderColor: vipTier != 'FREE' 
                              ? AppColors.primary.withOpacity(0.18) 
                              : AppColors.cardBorder,
                          child: Row(
                            children: [
                              // Avatar Container with VIP border
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(colors: avatarGradient),
                                  boxShadow: vipTier != 'FREE' ? [
                                    BoxShadow(
                                      color: avatarGradient[0].withOpacity(0.2),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    )
                                  ] : null,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: CircleAvatar(
                                  radius: 19,
                                  backgroundColor: AppColors.background,
                                  child: Text(
                                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      color: vipTier != 'FREE' ? avatarGradient[0] : AppColors.textSecondary, 
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 14
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
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
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        VipBadge(tier: vipTier, fontSize: 8),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: levelColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isAr ? 'مستوى $level' : 'Lvl $level',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: levelColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '+${CurrencyFormatter.format(commission, home.dashboard?.country ?? '', isAr)}',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveStatBox({
    required String label, 
    required String value, 
    required Color color, 
    required IconData icon,
    required int filterValue
  }) {
    final bool isSelected = _selectedLevelFilter == filterValue;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLevelFilter = isSelected ? 0 : filterValue;
          _applyFilters();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ] : null,
        ),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          borderColor: isSelected ? color.withOpacity(0.4) : AppColors.cardBorder,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isSelected ? Colors.white : color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesTimelineItem(String title, String rates, Color color, bool isBold) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  rates,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10.5,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int value) {
    final bool isSelected = _selectedLevelFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedLevelFilter = selected ? value : 0;
          _applyFilters();
        });
      },
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.cardBorder,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }
}
