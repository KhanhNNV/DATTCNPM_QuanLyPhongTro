import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/landlord_app/home_page/quick_action_item.dart';
import '../../../core/constants/app_colors.dart';
import '../deposit_page/deposit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // --- DANH SÁCH CHỨC NĂNG: THAO TÁC THƯỜNG DÙNG ---
  List<QuickActionItem> _getQuickActions(BuildContext context) {
    return [
      QuickActionItem(
        title: 'Cọc giữ chỗ',
        icon: Icons.handshake_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DepositScreen(
                areaId: selectedArea.id,
              ),
            ),
          );
        },
      ),
      QuickActionItem(
        title: 'Lập hợp đồng mới',
        icon: Icons.assignment_turned_in_outlined,
        onTap: () => _navigateTo('Nút: Lập hợp đồng mới (OCR CCCD & Tạo tài khoản)'),
      ),
      QuickActionItem(
        title: 'Trả phòng',
        icon: Icons.gite_outlined,
        onTap: () => _navigateTo('Nút: Thanh lý hợp đồng & quyết toán cọc'),
      ),
      QuickActionItem(
        title: 'Chốt điện/nước',
        icon: Icons.receipt_long_outlined,
        onTap: () => _navigateTo('Nút: Lập hóa đơn lẻ'),
      ),
      QuickActionItem(
        title: 'Xem hóa đơn',
        icon: Icons.calculate_outlined,
        onTap: () => _navigateTo('Nút: Chốt số điện nước & Xuất hóa đơn tự động'),
      ),
      QuickActionItem(
        title: 'Hóa đơn cần thu tiền',
        icon: Icons.payments_outlined,
        onTap: () => _navigateTo('Nút: Danh sách hóa đơn tích hợp VietQR'),
      ),
    ];
  }

  // --- DANH SÁCH CHỨC NĂNG: MENU QUẢN LÝ NHÀ TRỌ ---
  List<QuickActionItem> _getManagementMenu(BuildContext context) {
    return [
      QuickActionItem(
        title: 'Quản lý Sự cố',
        icon: Icons.build_circle_outlined,
        badgeText: '0/10', // Hiển thị badge dạng chuỗi như ảnh dưới
        onTap: () => _navigateTo('Nút: Tiếp nhận & Cập nhật trạng thái sự cố'),
      ),
      QuickActionItem(
        title: 'Cấu hình Khu trọ',
        icon: Icons.business_outlined,
        onTap: () => _navigateTo('Nút: Tinh chỉnh phòng đơn / Dịch vụ'),
      ),
      QuickActionItem(
        title: 'Thiết lập Chữ ký',
        icon: Icons.draw_outlined,
        onTap: () => _navigateTo('Nút: Thiết lập chữ ký số hệ thống'),
      ),
      QuickActionItem(
        title: 'Thống kê Doanh thu',
        icon: Icons.analytics_outlined,
        onTap: () => _navigateTo('Nút: Thống kê hóa đơn và nợ xấu'),
      ),
    ];
  }

  void _navigateTo(String featureName) {
    // Thay thế bằng logic điều hướng Navigator.push thực tế của bạn
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Điều hướng đến: $featureName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quickActions = _getQuickActions(context);
    final managementItems = _getManagementMenu(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: THAO TÁC THƯỜNG DÙNG ---
            _buildSectionHeader(
              title: 'Thao tác thường dùng',
              subtitle: 'Thực hiện tác vụ nhanh để quản lý...',
            ),
            const SizedBox(height: 12),
            _buildGridMenu(quickActions),

            const SizedBox(height: 24),

            // --- SECTION 2: MENU QUẢN LÝ NHÀ TRỌ ---
            _buildSectionHeader(
              title: 'Menu quản lý nhà trọ',
              subtitle: 'Quản lý đối tượng nghiệp vụ trong...',
            ),
            const SizedBox(height: 12),
            _buildGridMenu(managementItems),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị Tiêu đề phân đoạn nghiệp vụ
  Widget _buildSectionHeader({required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.help, color: Colors.grey[400], size: 22),
          onPressed: () {
          },
        )
      ],
    );
  }

  // Lưới hiển thị các thẻ Card
  Widget _buildGridMenu(List<QuickActionItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,         // Chia làm 3 cột đồng đều
        crossAxisSpacing: 10,      // Khoảng cách ngang giữa các ô
        mainAxisSpacing: 10,       // Khoảng cách dọc giữa các ô
        childAspectRatio: 0.85,    // Tỷ lệ khung hình của ô (Rộng / Cao) nhằm đảm bảo hiển thị đủ text 2 dòng
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildCardItem(item);
      },
    );
  }

  // Cấu trúc chi tiết của từng thẻ Chức năng (Card)
  Widget _buildCardItem(QuickActionItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Khung nền trắng của Thẻ
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Khối bao bọc Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.iconColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    color: item.iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                // Tiêu đề chữ chức năng
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF263238),
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // --- XỬ LÝ HIỂN THỊ BADGE THÔNG BÁO GÓC PHẢI ---
          if (item.badgeCount != null || item.badgeText != null)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  item.badgeText ?? '${item.badgeCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}