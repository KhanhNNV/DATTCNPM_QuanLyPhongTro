import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TenantMainBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const TenantMainBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTabSelected,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Hóa đơn'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Thông báo'),
      ],
    );
  }
}