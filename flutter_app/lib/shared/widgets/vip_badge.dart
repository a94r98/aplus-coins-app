import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class VipBadge extends StatelessWidget {
  final String tier;
  final double fontSize;

  const VipBadge({super.key, required this.tier, this.fontSize = 12});

  Color get _tierColor {
    switch (tier.toUpperCase()) {
      case 'VIP1':
        return AppColors.vip1;
      case 'VIP2':
        return AppColors.vip2;
      case 'VIP3':
        return AppColors.vip3;
      case 'VIP4':
        return const Color(0xFFEC4899); // Pink
      case 'VIP5':
        return const Color(0xFFEF4444); // Red
      case 'VIP6':
        return const Color(0xFF10B981); // Emerald Green
      case 'VIP7':
        return const Color(0xFF06B6D4); // Cyan
      case 'VIP8':
        return const Color(0xFFF97316); // Orange
      case 'VIP9':
        return const Color(0xFF84CC16); // Lime
      case 'VIP10':
        return const Color(0xFF6366F1); // Indigo
      default:
        return AppColors.vipFree;
    }
  }

  String get _label {
    final upper = tier.toUpperCase();
    switch (upper) {
      case 'VIP1':
        return '⭐ VIP1';
      case 'VIP2':
        return '💎 VIP2';
      case 'VIP3':
        return '👑 VIP3';
      case 'VIP4':
        return '⚡ VIP4';
      case 'VIP5':
        return '🔥 VIP5';
      case 'VIP6':
        return '🚀 VIP6';
      case 'VIP7':
        return '💥 VIP7';
      case 'VIP8':
        return '🛡️ VIP8';
      case 'VIP9':
        return '🏆 VIP9';
      case 'VIP10':
        return '🔮 VIP10';
      default:
        return '🆓 Free';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _tierColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _tierColor.withOpacity(0.5), width: 1),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _tierColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}
