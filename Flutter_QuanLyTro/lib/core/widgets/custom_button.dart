import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 8.0,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBgColor = backgroundColor ?? AppColors.primary;
    final defaultTextColor = textColor ?? Colors.white;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: defaultBgColor,
        foregroundColor: defaultTextColor,
        disabledBackgroundColor: defaultBgColor.withOpacity(0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      onPressed: (isLoading || onPressed == null) ? null : onPressed,
      child: isLoading
          ? SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          color: defaultTextColor,
          strokeWidth: 2.5,
        ),
      )
          : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}