import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final List<Color>? colors;
  final double? width;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.colors,
    this.width,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
    )..value = 1.0;
    _scaleAnimation = _scaleController.drive(CurveTween(curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> gradientColors = widget.colors ??
        [const Color(0xFF2FD3C6), AppColors.primary];

    return GestureDetector(
      onTapDown: (_) => _scaleController.reverse(),
      onTapUp: (_) {
        _scaleController.forward();
        widget.onPressed?.call();
      },
      onTapCancel: () => _scaleController.forward(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width ?? double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.onPressed == null
                  ? [Colors.grey.shade400, Colors.grey.shade300]
                  : gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.onPressed == null
                ? []
                : [
                    BoxShadow(
                      color: gradientColors.last.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    widget.text,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
