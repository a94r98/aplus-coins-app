import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../auth/auth_controller.dart';
import 'home_controller.dart';
import '../wallet/wallet_screen.dart';
import '../vip/vip_screen.dart';

class StoreTab extends StatefulWidget {
  const StoreTab({super.key});

  @override
  State<StoreTab> createState() => _StoreTabState();
}

class _StoreTabState extends State<StoreTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().fetchStoreOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final home = context.watch<HomeController>();
    final isAr = !auth.isEnglish;

    final double balance = home.dashboard?.balance ?? 0.0;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            isAr ? 'المتجر الإلكتروني' : 'Coinz Store',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(130),
            child: Column(
              children: [
                // ── available balance header card ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.wallet, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? 'الرصيد المتاح' : 'Available Balance',
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary),
                                ),
                                Text(
                                  '${balance.toStringAsFixed(0)} ${isAr ? 'كونز' : 'Coinz'}',
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.accent),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                                );
                              },
                              icon: const Icon(Icons.account_balance_wallet_rounded, size: 14, color: AppColors.primary),
                              label: Text(
                                isAr ? 'المحفظة' : 'Wallet',
                                style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 4),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const VipScreen()),
                                );
                              },
                              icon: const Icon(Icons.star_rounded, size: 14, color: AppColors.vip3),
                              label: Text(
                                isAr ? 'VIP ترقية' : 'VIP Tiers',
                                style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.vip3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // TabBar Selector
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.primary,
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    tabs: [
                      Tab(text: isAr ? 'شراء كروت' : 'Cards'),
                      Tab(text: isAr ? 'عملات الدردشة' : 'Chat Coins'),
                      Tab(text: isAr ? 'شحن الألعاب' : 'Games'),
                      Tab(text: isAr ? 'تحويل العملات' : 'Cashout'),
                      Tab(text: isAr ? 'سجل الطلبات' : 'Order History'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            CardsStoreTab(),
            ChatCoinsStoreTab(),
            GamesStoreTab(),
            CurrencyExchangeStoreTab(),
            OrdersHistoryTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. CARDS STORE TAB
// ─────────────────────────────────────────────────────────────────────────────
class CardsStoreTab extends StatefulWidget {
  const CardsStoreTab({super.key});

  @override
  State<CardsStoreTab> createState() => _CardsStoreTabState();
}

class _CardsStoreTabState extends State<CardsStoreTab> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController(text: '+964');
  String _selectedBrand = 'Asiacell';
  String _selectedDenomination = '5,000 IQD';
  double _costInCoins = 5.0;

  final List<Map<String, dynamic>> _brands = [
    {'name': 'Asiacell', 'color': Colors.deepPurple, 'icon': Icons.cell_tower_rounded},
    {'name': 'Zain Iraq', 'color': Colors.black87, 'icon': Icons.signal_cellular_alt_rounded},
    {'name': 'Korek', 'color': Colors.orange, 'icon': Icons.network_cell_rounded},
    {'name': 'Google Play', 'color': Colors.teal, 'icon': Icons.shop_rounded},
    {'name': 'iTunes', 'color': Colors.pink, 'icon': Icons.music_note_rounded},
  ];

  final Map<String, List<Map<String, dynamic>>> _denomData = {
    'Asiacell': [
      {'label': '5,000 IQD', 'cost': 5.0},
      {'label': '10,000 IQD', 'cost': 10.0},
      {'label': '15,000 IQD', 'cost': 15.0},
      {'label': '25,000 IQD', 'cost': 25.0},
    ],
    'Zain Iraq': [
      {'label': '5,000 IQD', 'cost': 5.0},
      {'label': '10,000 IQD', 'cost': 10.0},
      {'label': '15,000 IQD', 'cost': 15.0},
      {'label': '25,000 IQD', 'cost': 25.0},
    ],
    'Korek': [
      {'label': '5,000 IQD', 'cost': 5.0},
      {'label': '10,000 IQD', 'cost': 10.0},
      {'label': '15,000 IQD', 'cost': 15.0},
      {'label': '25,000 IQD', 'cost': 25.0},
    ],
    'Google Play': [
      {'label': '\$5 Gift Card', 'cost': 5.5},
      {'label': '\$10 Gift Card', 'cost': 11.0},
      {'label': '\$25 Gift Card', 'cost': 27.0},
    ],
    'iTunes': [
      {'label': '\$5 Gift Card', 'cost': 5.5},
      {'label': '\$10 Gift Card', 'cost': 11.0},
      {'label': '\$25 Gift Card', 'cost': 27.0},
    ],
  };

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _updateCost() {
    final items = _denomData[_selectedBrand] ?? [];
    final match = items.firstWhere(
      (element) => element['label'] == _selectedDenomination,
      orElse: () => items.isNotEmpty ? items[0] : {'cost': 0.0},
    );
    setState(() {
      _costInCoins = match['cost'] as double;
    });
  }

  void _submit(HomeController home, bool isAr) async {
    if (!_formKey.currentState!.validate()) return;

    if ((home.dashboard?.availableBalance ?? 0) < _costInCoins) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'رصيدك المتاح غير كافٍ لإتمام عملية الشراء' : 'Insufficient available Coinz balance'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await home.submitStoreOrder(
      category: 'CARDS',
      productName: '$_selectedBrand - $_selectedDenomination',
      coinsPrice: _costInCoins,
      details: {
        'brand': _selectedBrand,
        'denomination': _selectedDenomination,
        'phoneNumber': _phoneCtrl.text.trim(),
      },
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم إرسال طلب الشراء بنجاح وجاري المراجعة 🎉' : 'Order submitted successfully! 🎉'),
          backgroundColor: AppColors.accent,
        ),
      );
      _phoneCtrl.text = '+964';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(home.error ?? (isAr ? 'فشل إرسال الطلب' : 'Failed to submit order')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final isAr = !context.watch<AuthController>().isEnglish;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Visual Brands Catalog ──
          Text(
            isAr ? 'اختر الشركة أو نوع الكارت:' : 'Select Provider / Card Type:',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _brands.length,
              itemBuilder: (context, index) {
                final b = _brands[index];
                final bool isSelected = _selectedBrand == b['name'];
                final Color brandColor = b['color'] as Color;
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedBrand = b['name'] as String;
                      _selectedDenomination = _denomData[_selectedBrand]![0]['label'] as String;
                    });
                    _updateCost();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: brandColor.withOpacity(0.25),
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ] : null,
                      ),
                      child: GlassCard(
                        padding: const EdgeInsets.all(12),
                        borderColor: isSelected ? brandColor : AppColors.cardBorder,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(b['icon'] as IconData, color: isSelected ? brandColor : AppColors.textSecondary, size: 24),
                            const SizedBox(height: 8),
                            Text(
                              b['name'] as String,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // ── Denominations Chips ──
          Text(
            isAr ? 'اختر فئة كارت الشحن:' : 'Select Card Denomination:',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _denomData[_selectedBrand]!.map((d) {
              final label = d['label'] as String;
              final cost = d['cost'] as double;
              final bool isSelected = _selectedDenomination == label;
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDenomination = label;
                  });
                  _updateCost();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.12) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                      if (isSelected) const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '$cost ${isAr ? 'كونز' : 'Coinz'}',
                            style: const TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── Recipient Form ──
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _phoneCtrl,
                    style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo', fontSize: 13),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: isAr ? 'رقم الهاتف المستلم للكود' : 'Recipient Phone Number',
                      labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
                      helperText: isAr ? 'أدخل الرقم الدولي شاملاً رمز الدولة (مثال: +964)' : 'Include country code prefix (e.g. +964)',
                      helperStyle: const TextStyle(fontSize: 10),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 8) {
                        return isAr ? 'أدخل رقم هاتف صالح للاستلام' : 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? 'السعر الإجمالي المطلوب:' : 'Required Total Price:',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        '$_costInCoins ${isAr ? 'كونز' : 'Coinz'}',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GradientButton(
                    text: isAr ? 'إرسال طلب الشراء فوراً' : 'Submit Card Request',
                    isLoading: home.isLoading,
                    onPressed: home.isLoading ? null : () => _submit(home, isAr),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. CHAT COINS STORE TAB
// ─────────────────────────────────────────────────────────────────────────────
class ChatCoinsStoreTab extends StatefulWidget {
  const ChatCoinsStoreTab({super.key});

  @override
  State<ChatCoinsStoreTab> createState() => _ChatCoinsStoreTabState();
}

class _ChatCoinsStoreTabState extends State<ChatCoinsStoreTab> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _coinsQtyCtrl = TextEditingController();
  String _selectedApp = 'Haya Chat';
  double _costInCoins = 0.0;

  final List<Map<String, dynamic>> _apps = [
    {'name': 'Haya Chat', 'icon': Icons.chat_rounded, 'color': Colors.blue},
    {'name': 'Zena Live', 'icon': Icons.live_tv_rounded, 'color': Colors.pink},
    {'name': 'Ahlan Chat', 'icon': Icons.forum_rounded, 'color': Colors.purple},
  ];

  final double _rate = 0.05; // 0.05 Coinz per App Coin

  @override
  void dispose() {
    _idCtrl.dispose();
    _coinsQtyCtrl.dispose();
    super.dispose();
  }

  void _calculatePrice(String val) {
    if (val.trim().isEmpty) {
      setState(() {
        _costInCoins = 0.0;
      });
      return;
    }
    final qty = int.tryParse(val.trim()) ?? 0;
    setState(() {
      _costInCoins = qty * _rate;
    });
  }

  void _submit(HomeController home, bool isAr) async {
    if (!_formKey.currentState!.validate()) return;

    if ((home.dashboard?.availableBalance ?? 0) < _costInCoins) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'رصيدك المتاح غير كافٍ لإتمام عملية الشراء' : 'Insufficient available Coinz balance'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await home.submitStoreOrder(
      category: 'CHAT_COINS',
      productName: '$_selectedApp - ${_coinsQtyCtrl.text} Coins',
      coinsPrice: _costInCoins,
      details: {
        'appName': _selectedApp,
        'appId': _idCtrl.text.trim(),
        'appCoins': int.parse(_coinsQtyCtrl.text.trim()),
      },
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم إرسال طلب شحن التطبيق بنجاح وجاري المراجعة 🎉' : 'Chat recharge request submitted! 🎉'),
          backgroundColor: AppColors.accent,
        ),
      );
      _idCtrl.clear();
      _coinsQtyCtrl.clear();
      setState(() {
        _costInCoins = 0.0;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(home.error ?? (isAr ? 'فشل إرسال الطلب' : 'Failed to submit request')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final isAr = !context.watch<AuthController>().isEnglish;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Chat Apps Selection ──
          Text(
            isAr ? 'اختر تطبيق الغرف والدردشة:' : 'Select Room/Chat App:',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: _apps.map((app) {
              final bool isSelected = _selectedApp == app['name'];
              final Color appColor = app['color'] as Color;
              
              return Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedApp = app['name'] as String;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected ? [
                        BoxShadow(color: appColor.withOpacity(0.15), blurRadius: 10, spreadRadius: 1),
                      ] : null,
                    ),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      borderColor: isSelected ? appColor : AppColors.cardBorder,
                      child: Column(
                        children: [
                          Icon(app['icon'] as IconData, color: isSelected ? appColor : AppColors.textSecondary, size: 24),
                          const SizedBox(height: 6),
                          Text(
                            app['name'] as String,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ── Checkout Form ──
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _idCtrl,
                    style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo', fontSize: 13),
                    decoration: InputDecoration(
                      labelText: isAr ? 'رقم الحساب المعرّف للتطبيق (ID)' : 'User Account ID',
                      labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      prefixIcon: const Icon(Icons.tag, color: AppColors.primary),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return isAr ? 'رقم الحساب مطلوب للإرسال' : 'ID is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _coinsQtyCtrl,
                    style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo', fontSize: 13),
                    keyboardType: TextInputType.number,
                    onChanged: _calculatePrice,
                    decoration: InputDecoration(
                      labelText: isAr ? 'عدد العملات المراد شحنها بالتطبيق' : 'Amount of App Coins to Recharge',
                      labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      prefixIcon: const Icon(Icons.stars_rounded, color: AppColors.primary),
                      helperText: isAr ? 'سعر التحويل: 1 عملة تطبيق = 0.05 كونز' : 'Exchange Rate: 1 App Coin = 0.05 Coinz',
                      helperStyle: const TextStyle(fontSize: 10),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return isAr ? 'العدد مطلوب' : 'Quantity is required';
                      }
                      final qty = int.tryParse(v.trim());
                      if (qty == null || qty <= 0) {
                        return isAr ? 'أدخل عدداً صحيحاً صالحاً' : 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? 'التكلفة بالكونزات:' : 'Required Price (Coinz):',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${_costInCoins.toStringAsFixed(2)} ${isAr ? 'كونز' : 'Coinz'}',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    text: isAr ? 'طلب شحن العملات' : 'Submit Coins Request',
                    isLoading: home.isLoading,
                    onPressed: home.isLoading ? null : () => _submit(home, isAr),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. GAMES RECHARGE TAB
// ─────────────────────────────────────────────────────────────────────────────
class GamesStoreTab extends StatefulWidget {
  const GamesStoreTab({super.key});

  @override
  State<GamesStoreTab> createState() => _GamesStoreTabState();
}

class _GamesStoreTabState extends State<GamesStoreTab> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  String _selectedGame = 'PUBG Mobile';
  String _selectedPackage = '60 UC';
  double _costInCoins = 1.2;

  final List<Map<String, dynamic>> _games = [
    {'name': 'PUBG Mobile', 'icon': Icons.videogame_asset, 'color': Colors.amber},
    {'name': 'Yalla Ludo', 'icon': Icons.casino, 'color': Colors.red},
  ];

  final Map<String, List<Map<String, dynamic>>> _packageData = {
    'PUBG Mobile': [
      {'label': '60 UC', 'cost': 1.2},
      {'label': '325 UC', 'cost': 6.0},
      {'label': '660 UC', 'cost': 12.0},
      {'label': '1800 UC', 'cost': 30.0},
    ],
    'Yalla Ludo': [
      {'label': '50 Diamonds', 'cost': 1.0},
      {'label': '250 Diamonds', 'cost': 4.5},
      {'label': '500 Diamonds', 'cost': 9.0},
    ],
  };

  void _updateCost() {
    final items = _packageData[_selectedGame] ?? [];
    final match = items.firstWhere(
      (element) => element['label'] == _selectedPackage,
      orElse: () => items.isNotEmpty ? items[0] : {'cost': 0.0},
    );
    setState(() {
      _costInCoins = match['cost'] as double;
    });
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  void _submit(HomeController home, bool isAr) async {
    if (!_formKey.currentState!.validate()) return;

    if ((home.dashboard?.availableBalance ?? 0) < _costInCoins) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'رصيدك المتاح غير كافٍ لإتمام عملية الشراء' : 'Insufficient available Coinz balance'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await home.submitStoreOrder(
      category: 'GAMES',
      productName: '$_selectedGame - $_selectedPackage',
      coinsPrice: _costInCoins,
      details: {
        'gameName': _selectedGame,
        'gameId': _idCtrl.text.trim(),
        'package': _selectedPackage,
      },
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم إرسال طلب الشحن بنجاح وجاري المراجعة 🎉' : 'Game recharge request submitted! 🎉'),
          backgroundColor: AppColors.accent,
        ),
      );
      _idCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(home.error ?? (isAr ? 'فشل إرسال الطلب' : 'Failed to submit request')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final isAr = !context.watch<AuthController>().isEnglish;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Game Selection ──
          Text(
            isAr ? 'اختر اللعبة المراد شحنها:' : 'Select Game to Recharge:',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: _games.map((g) {
              final bool isSelected = _selectedGame == g['name'];
              final Color gameColor = g['color'] as Color;
              
              return Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedGame = g['name'] as String;
                      _selectedPackage = _packageData[_selectedGame]![0]['label'] as String;
                    });
                    _updateCost();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected ? [
                        BoxShadow(color: gameColor.withOpacity(0.15), blurRadius: 10, spreadRadius: 1),
                      ] : null,
                    ),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      borderColor: isSelected ? gameColor : AppColors.cardBorder,
                      child: Column(
                        children: [
                          Icon(g['icon'] as IconData, color: isSelected ? gameColor : AppColors.textSecondary, size: 24),
                          const SizedBox(height: 6),
                          Text(
                            g['name'] as String,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ── Selectable package tiles ──
          Text(
            isAr ? 'اختر باقة الشحن المتوفرة:' : 'Select Recharge Package:',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _packageData[_selectedGame]!.length,
            itemBuilder: (context, index) {
              final p = _packageData[_selectedGame]![index];
              final label = p['label'] as String;
              final cost = p['cost'] as double;
              final bool isSelected = _selectedPackage == label;
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedPackage = label;
                  });
                  _updateCost();
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$cost ${isAr ? 'كونز' : 'Coinz'}',
                              style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Checkout Form ──
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _idCtrl,
                    style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo', fontSize: 13),
                    decoration: InputDecoration(
                      labelText: isAr ? 'معرف حساب اللاعب في اللعبة (Player ID)' : 'Player Account ID',
                      labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      prefixIcon: const Icon(Icons.tag, color: AppColors.primary),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return isAr ? 'رقم حساب اللاعب مطلوب' : 'Game ID is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? 'سعر الباقة الإجمالي:' : 'Total Package Cost:',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        '$_costInCoins ${isAr ? 'كونز' : 'Coinz'}',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GradientButton(
                    text: isAr ? 'طلب الشحن الفوري' : 'Submit Game Recharge',
                    isLoading: home.isLoading,
                    onPressed: home.isLoading ? null : () => _submit(home, isAr),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. CURRENCY / WALLETS EXCHANGE TAB
// ─────────────────────────────────────────────────────────────────────────────
class CurrencyExchangeStoreTab extends StatefulWidget {
  const CurrencyExchangeStoreTab({super.key});

  @override
  State<CurrencyExchangeStoreTab> createState() => _CurrencyExchangeStoreTabState();
}

class _CurrencyExchangeStoreTabState extends State<CurrencyExchangeStoreTab> {
  final _formKey = GlobalKey<FormState>();
  final _coinzQtyCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  String _selectedWallet = 'Zain Cash';
  double _equivalentAmount = 0.0;

  final List<Map<String, dynamic>> _wallets = [
    {'name': 'Zain Cash', 'color': Colors.red, 'icon': Icons.account_balance_wallet_rounded},
    {'name': 'AsiaPay', 'color': Colors.purple, 'icon': Icons.wallet_giftcard_rounded},
    {'name': 'SuperKey', 'color': Colors.blue, 'icon': Icons.vpn_key_rounded},
    {'name': 'USDT (TRC-20)', 'color': Colors.teal, 'icon': Icons.currency_bitcoin_rounded},
    {'name': 'TRX', 'color': Colors.redAccent, 'icon': Icons.circle_rounded},
  ];

  @override
  void dispose() {
    _coinzQtyCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  void _calculatePayout(String val) {
    if (val.trim().isEmpty) {
      setState(() {
        _equivalentAmount = 0.0;
      });
      return;
    }
    final coinz = double.tryParse(val.trim()) ?? 0.0;

    if (_selectedWallet == 'USDT (TRC-20)' || _selectedWallet == 'TRX') {
      setState(() {
        _equivalentAmount = coinz * 1.0;
      });
    } else {
      setState(() {
        _equivalentAmount = coinz * 1600.0;
      });
    }
  }

  void _submit(HomeController home, bool isAr) async {
    if (!_formKey.currentState!.validate()) return;

    final coinzAmount = double.parse(_coinzQtyCtrl.text.trim());

    if ((home.dashboard?.availableBalance ?? 0) < coinzAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'رصيدك المتاح غير كافٍ لإتمام التبادل' : 'Insufficient available Coinz balance'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final isCrypto = (_selectedWallet == 'USDT (TRC-20)' || _selectedWallet == 'TRX');
    final payoutText = isCrypto 
        ? '\$${_equivalentAmount.toStringAsFixed(2)}' 
        : '${NumberFormat('#,##0', 'en_US').format(_equivalentAmount)} د.ع';

    final success = await home.submitStoreOrder(
      category: 'CURRENCY_EXCHANGE',
      productName: 'Exchange Coinz for $_selectedWallet ($payoutText)',
      coinsPrice: coinzAmount,
      details: {
        'walletBrand': _selectedWallet,
        'coinzAmount': coinzAmount,
        'receivedAmountText': payoutText,
        'walletNumber': _destCtrl.text.trim(),
      },
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم تقديم طلب تبادل الرصيد بنجاح 🎉' : 'Exchange request submitted! 🎉'),
          backgroundColor: AppColors.accent,
        ),
      );
      _coinzQtyCtrl.clear();
      _destCtrl.clear();
      setState(() {
        _equivalentAmount = 0.0;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(home.error ?? (isAr ? 'فشل تقديم الطلب' : 'Failed to submit exchange')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final isAr = !context.watch<AuthController>().isEnglish;

    final isCrypto = (_selectedWallet == 'USDT (TRC-20)' || _selectedWallet == 'TRX');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Select Wallet Cards ──
          Text(
            isAr ? 'اختر المحفظة المستلمة:' : 'Select Target Wallet:',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _wallets.length,
              itemBuilder: (context, index) {
                final w = _wallets[index];
                final bool isSelected = _selectedWallet == w['name'];
                final Color wColor = w['color'] as Color;
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedWallet = w['name'] as String;
                    });
                    _calculatePayout(_coinzQtyCtrl.text);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected ? [
                          BoxShadow(color: wColor.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)
                        ] : null,
                      ),
                      child: GlassCard(
                        padding: const EdgeInsets.all(12),
                        borderColor: isSelected ? wColor : AppColors.cardBorder,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(w['icon'] as IconData, color: isSelected ? wColor : AppColors.textSecondary, size: 24),
                            const SizedBox(height: 8),
                            Text(
                              w['name'] as String,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // ── Exchange Form ──
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _coinzQtyCtrl,
                    style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo', fontSize: 13),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: _calculatePayout,
                    decoration: InputDecoration(
                      labelText: isAr ? 'كمية الكونزات المراد تحويلها' : 'Amount of Coinz to Exchange',
                      labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      prefixIcon: const Icon(Icons.wallet, color: AppColors.primary),
                      helperText: isCrypto
                          ? (isAr ? 'معدل الصرف: 1 كونز = 1.00 دولار' : 'Rate: 1 Coinz = \$1.00 USD')
                          : (isAr ? 'معدل الصرف: 1 كونز = 1,600 دينار عراقي' : 'Rate: 1 Coinz = 1,600 IQD'),
                      helperStyle: const TextStyle(fontSize: 10),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return isAr ? 'أدخل عدد الكونزات' : 'Amount is required';
                      }
                      final c = double.tryParse(v.trim());
                      if (c == null || c <= 0) {
                        return isAr ? 'أدخل مبلغاً صالحاً' : 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _destCtrl,
                    style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo', fontSize: 13),
                    decoration: InputDecoration(
                      labelText: isCrypto 
                          ? (isAr ? 'عنوان المحفظة الرقمية (USDT/TRX Address)' : 'Crypto Wallet Address')
                          : (isAr ? 'رقم الهاتف للمحفظة الكاش المستلمة' : 'Recipient Cash Wallet Phone'),
                      labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      prefixIcon: Icon(isCrypto ? Icons.qr_code_scanner : Icons.phone, color: AppColors.primary),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return isAr ? 'الرقم أو عنوان المحفظة مطلوب للاستلام' : 'Recipient details required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? 'المبلغ المستلم التقريبي:' : 'Estimated Cash Payout:',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        isCrypto 
                            ? '\$${_equivalentAmount.toStringAsFixed(2)}' 
                            : '${NumberFormat('#,##0', 'en_US').format(_equivalentAmount)} د.ع',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    text: isAr ? 'تقديم طلب التحويل النقدي' : 'Submit Cashout Request',
                    isLoading: home.isLoading,
                    onPressed: home.isLoading ? null : () => _submit(home, isAr),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. ORDERS HISTORY TAB (Expandable ledger list with state filters)
// ─────────────────────────────────────────────────────────────────────────────
class OrdersHistoryTab extends StatefulWidget {
  const OrdersHistoryTab({super.key});

  @override
  State<OrdersHistoryTab> createState() => _OrdersHistoryTabState();
}

class _OrdersHistoryTabState extends State<OrdersHistoryTab> {
  String _selectedStatusFilter = 'ALL'; // 'ALL', 'PENDING', 'APPROVED', 'REJECTED'
  int? _expandedOrderId;

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final isAr = !context.watch<AuthController>().isEnglish;

    // Filtered orders
    final filtered = home.storeOrders.where((order) {
      if (_selectedStatusFilter == 'ALL') return true;
      final status = (order['status'] ?? '').toString().toUpperCase();
      return status == _selectedStatusFilter;
    }).toList();

    return Column(
      children: [
        // Filter Chips Header
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip(isAr ? 'الكل' : 'All', 'ALL'),
              const SizedBox(width: 8),
              _buildFilterChip(isAr ? 'المعلقة' : 'Pending', 'PENDING', AppColors.warning),
              const SizedBox(width: 8),
              _buildFilterChip(isAr ? 'المقبولة' : 'Approved', 'APPROVED', AppColors.accent),
              const SizedBox(width: 8),
              _buildFilterChip(isAr ? 'المرفوضة' : 'Rejected', 'REJECTED', AppColors.error),
            ],
          ),
        ),
        
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await home.fetchStoreOrders();
            },
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.primary.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text(
                              isAr ? 'لا توجد طلبات تطابق الفلتر' : 'No orders match criteria',
                              style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      final int orderId = order['id'] as int? ?? 0;
                      final String productName = order['product_name'] ?? '';
                      final String category = order['category'] ?? '';
                      final double coinsPrice = double.tryParse(order['coins_price']?.toString() ?? '0') ?? 0.0;
                      final String status = order['status'] ?? 'PENDING';
                      final String? rejectionReason = order['rejection_reason'];
                      final String dateStr = order['created_at']?.toString() ?? '';
                      final dateFormatted = dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;
                      
                      final Map<String, dynamic> details = order['details'] is Map 
                          ? order['details'] as Map<String, dynamic> 
                          : {};

                      final bool isExpanded = _expandedOrderId == orderId;

                      Color statusColor;
                      String statusText;
                      IconData statusIcon;

                      switch (status.toUpperCase()) {
                        case 'APPROVED':
                          statusColor = AppColors.accent;
                          statusText = isAr ? 'تم الشحن/القبول' : 'Completed';
                          statusIcon = Icons.check_circle_outline_rounded;
                          break;
                        case 'REJECTED':
                          statusColor = AppColors.error;
                          statusText = isAr ? 'مرفوض' : 'Rejected';
                          statusIcon = Icons.error_outline_rounded;
                          break;
                        default:
                          statusColor = AppColors.warning;
                          statusText = isAr ? 'قيد الانتظار' : 'Pending';
                          statusIcon = Icons.hourglass_empty_rounded;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: status.toUpperCase() == 'PENDING' ? [
                              BoxShadow(
                                color: AppColors.warning.withOpacity(0.04),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                            ] : null,
                          ),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            borderColor: isExpanded 
                                ? AppColors.primary.withOpacity(0.4) 
                                : status.toUpperCase() == 'PENDING'
                                    ? AppColors.warning.withOpacity(0.2)
                                    : AppColors.cardBorder,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _expandedOrderId = isExpanded ? null : orderId;
                                });
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          productName,
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(statusIcon, color: statusColor, size: 12),
                                            const SizedBox(width: 4),
                                            Text(
                                              statusText,
                                              style: TextStyle(
                                                fontFamily: 'Cairo',
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: statusColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isAr ? 'التصنيف: $category' : 'Category: $category',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                      Text(
                                        '$coinsPrice ${isAr ? 'كونز' : 'Coinz'}',
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Expandable Details Section
                                  AnimatedCrossFade(
                                    firstChild: const SizedBox.shrink(),
                                    secondChild: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Divider(height: 20, color: AppColors.cardBorder),
                                        Text(
                                          isAr ? 'بيانات الشحن المستلمة:' : 'Receipt details submitted:',
                                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                        const SizedBox(height: 6),
                                        ...details.entries.map((entry) {
                                          final key = entry.key;
                                          final value = entry.value?.toString() ?? '---';
                                          
                                          // Localize keys for premium feel
                                          String localizedKey = key;
                                          if (isAr) {
                                            if (key == 'phoneNumber') localizedKey = 'رقم الهاتف';
                                            if (key == 'brand') localizedKey = 'الشركة';
                                            if (key == 'denomination') localizedKey = 'الفئة';
                                            if (key == 'appName') localizedKey = 'التطبيق';
                                            if (key == 'appId') localizedKey = 'معرّف الحساب (ID)';
                                            if (key == 'appCoins') localizedKey = 'كمية الشحن بالتطبيق';
                                            if (key == 'gameName') localizedKey = 'اللعبة';
                                            if (key == 'gameId') localizedKey = 'معرف اللاعب (Game ID)';
                                            if (key == 'package') localizedKey = 'الباقة';
                                            if (key == 'walletBrand') localizedKey = 'نوع محفظة الكاش';
                                            if (key == 'coinzAmount') localizedKey = 'عدد الكونز المخصوم';
                                            if (key == 'receivedAmountText') localizedKey = 'المبلغ النقدي المستلم';
                                            if (key == 'walletNumber') localizedKey = 'رقم/عنوان المحفظة المستلمة';
                                          }
                                          
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '$localizedKey:',
                                                  style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                                ),
                                                Text(
                                                  value,
                                                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        if (status.toUpperCase() == 'REJECTED' && rejectionReason != null && rejectionReason.isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.only(top: 8),
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.error.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 14),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    isAr ? 'سبب الرفض: $rejectionReason' : 'Reason: $rejectionReason',
                                                    style: const TextStyle(
                                                      fontFamily: 'Cairo',
                                                      fontSize: 10.5,
                                                      color: AppColors.error,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                    duration: const Duration(milliseconds: 250),
                                  ),
                                  
                                  const Divider(height: 20, color: AppColors.cardBorder),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        dateFormatted,
                                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                      ),
                                      Icon(
                                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, [Color? activeColor]) {
    final bool isSelected = _selectedStatusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = selected ? value : 'ALL';
        });
      },
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      selectedColor: activeColor ?? AppColors.primary,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? (activeColor ?? AppColors.primary) : AppColors.cardBorder,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}
