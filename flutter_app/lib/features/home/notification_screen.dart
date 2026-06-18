import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import 'home_controller.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().fetchNotifications();
    });
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'STORE_ORDER':
      case 'STORE_PURCHASE':
      case 'STORE_REFUND':
        return Icons.shopping_bag_outlined;
      case 'WITHDRAWAL':
      case 'WALLET':
      case 'WALLET_UPDATE':
        return Icons.account_balance_wallet_outlined;
      case 'REFERRAL':
      case 'REFERRAL_BONUS':
        return Icons.people_outline;
      case 'VIP_UPGRADE':
      case 'VIP_CLAIM':
        return Icons.stars_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toUpperCase()) {
      case 'STORE_ORDER':
      case 'STORE_PURCHASE':
        return AppColors.primary;
      case 'STORE_REFUND':
      case 'WITHDRAWAL':
      case 'WALLET':
        return AppColors.accent;
      case 'REFERRAL_BONUS':
        return Colors.purple;
      case 'VIP_UPGRADE':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isAr ? 'الإشعارات' : 'Notifications'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await home.fetchNotifications();
        },
        color: AppColors.primary,
        child: home.notifications.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Text(
                      isAr ? 'لا توجد إشعارات جديدة' : 'No notifications yet',
                      style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: home.notifications.length,
                itemBuilder: (context, index) {
                  final item = home.notifications[index];
                  final int id = item['id'] ?? 0;
                  final String title = item['title'] ?? '';
                  final String body = item['body'] ?? '';
                  final String type = item['type'] ?? 'GENERAL';
                  final bool isRead = item['is_read'] as bool? ?? false;
                  final String dateStr = item['created_at']?.toString() ?? '';
                  final timeText = dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;

                  final icon = _getIconForType(type);
                  final color = _getColorForType(type);

                  return GestureDetector(
                    onTap: () {
                      if (!isRead) {
                        home.markNotificationRead(id);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        borderColor: isRead ? AppColors.cardBorder : color.withOpacity(0.4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                color: color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 13,
                                            fontWeight: isRead ? FontWeight.bold : FontWeight.w900,
                                            color: isRead ? AppColors.textPrimary : Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        timeText,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    body,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (!isRead) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isAr ? 'تحديد كمقروء' : 'Mark read',
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
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
    );
  }
}
