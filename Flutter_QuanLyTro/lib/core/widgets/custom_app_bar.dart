import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool centerTitle;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double elevation;

  const CustomAppBar({
    super.key,
    required this.title,
    this.centerTitle = true,
    this.actions,
    this.bottom,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: elevation,
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize {
    return Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
  }
}