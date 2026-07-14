import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../notification/view_models/notification_view_model.dart';

class MainBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const MainBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {

    final unreadCount = context.select((NotificationViewModel vm) => vm.unreadCount);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTabSelected,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Khách thuê'),
        BottomNavigationBarItem(

          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
            backgroundColor: Colors.red,
            child: const Icon(Icons.notifications),
          ),
          label: 'Thông báo',
        ),
      ],
    );
  }
}