import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import '../home/home_controller.dart';
import '../auth/auth_controller.dart';
import 'wallet_controller.dart';
import '../../core/utils/currency_formatter.dart';

class WalletScreen extends StatefulWidget {
  final bool hideAppBar;
  const WalletScreen({super.key, this.hideAppBar = false});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletController>().loadWallet();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletController>();
    final home = context.watch<HomeController>();
    final auth = context.watch<AuthController>();
    final isAr = !auth.isEnglish;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: Text(isAr ? 'المحفظة المالية' : 'Wallet'),
              backgroundColor: AppColors.background,
              leading: const SizedBox(),
            ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await wallet.loadWallet();
            await home.refreshDashboard();
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Balance cards pulled directly from home/wallet controller ──
                Row(
                  children: [
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.accent, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              CurrencyFormatter.format(wallet.available, wallet.country, isAr),
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAr ? 'الرصيد المتاح' : 'Available Balance',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                        child: Column(
                          children: [
                            const Icon(Icons.history_toggle_off, color: AppColors.warning, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              CurrencyFormatter.format(wallet.pending, wallet.country, isAr),
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAr ? 'الرصيد المعلق' : 'Pending Balance',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Withdrawal History ──
                Text(
                  isAr ? 'سجل السحوبات' : 'Withdrawal History',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                if (wallet.withdrawalHistory.isEmpty && !wallet.isLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        isAr ? 'لا يوجد طلبات سحب سابقة' : 'No withdrawal requests yet',
                        style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                if (wallet.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                ...wallet.withdrawalHistory.map((tx) => _buildTransactionItem(tx, isAr)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction tx, bool isAr) {
    Color statusColor;
    String statusText;

    switch (tx.status.toUpperCase()) {
      case 'CONFIRMED':
      case 'SUCCESS':
        statusColor = AppColors.accent;
        statusText = isAr ? 'مكتمل' : 'Completed';
        break;
      case 'PENDING':
        statusColor = AppColors.warning;
        statusText = isAr ? 'قيد الانتظار' : 'Pending';
        break;
      case 'FAILED':
      case 'REJECTED':
        statusColor = AppColors.error;
        statusText = isAr ? 'مرفوض' : 'Rejected';
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = tx.status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                tx.status.toUpperCase() == 'CONFIRMED' || tx.status.toUpperCase() == 'SUCCESS'
                    ? Icons.done
                    : tx.status.toUpperCase() == 'PENDING'
                        ? Icons.hourglass_empty
                        : Icons.close,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tx.type.toUpperCase()} - ${tx.description ?? ''}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tx.createdAt.length > 10 ? tx.createdAt.substring(0, 10) : tx.createdAt,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${tx.amount < 0 ? '-' : '+'}${CurrencyFormatter.format(tx.amount.abs(), context.read<WalletController>().country, isAr)}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: tx.amount < 0 ? AppColors.error : AppColors.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
