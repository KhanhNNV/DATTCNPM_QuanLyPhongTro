import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/core/constants/app_colors.dart';

class QuickActionItem {
  final String title;
  final IconData icon;
  final Color iconColor;
  final int? badgeCount;
  final String? badgeText;
  final VoidCallback onTap;

  const QuickActionItem({
    required this.title,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.badgeCount,
    this.badgeText,
    required this.onTap,
  });
}