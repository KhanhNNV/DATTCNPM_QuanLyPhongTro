import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../landlord_app/home_page/quick_action_item.dart';
import '../contract/tenant_contract_pdf_viewer_screen.dart';
import '../contract/view_models/tenant_contract_view_model.dart';
import '../invoices/tenant_invoice_list_screen.dart';
import '../invoices/view_models/tenant_invoice_list_view_model.dart';
import '../main_layout/view_models/tenant_main_layout_view_model.dart';

class TenantHomeScreen extends StatefulWidget {
  const TenantHomeScreen({super.key});

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {

  // --- DANH SÁCH CHỨC NĂNG: QUẢN LÝ PHÒNG TRỌ ---
  List<QuickActionItem> _getRoomActions(BuildContext context,TenantMainLayoutViewModel viewModel) {
    return [
      QuickActionItem(
        title: 'Hợp đồng điện tử',
        icon: Icons.assignment_outlined,
        onTap: () {
          final contract = viewModel.currentContract;
          if (contract == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không tìm thấy thông tin hợp đồng hiện tại!')),
            );
            return;
          }

          final fileUrl = contract.contractFileUrl;
          if (fileUrl != null && fileUrl.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => TenantContractViewModel()..loadCurrentContract(),
                  child: const TenantContractPdfViewerScreen(),
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hợp đồng này chưa có file đính kèm!')),
            );
          }
        },
      ),
      QuickActionItem(
        title: 'Hóa đơn & Thanh toán',
        icon: Icons.receipt_long_outlined,
        badgeText: 'Mới',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (_) => TenantInvoiceListViewModel()..fetchInvoices(isRefresh: true),
                child: const TenantInvoiceListScreen(),
              ),
            ),
          );
        },
      ),
      QuickActionItem(
        title: 'Bạn cùng phòng',
        icon: Icons.group_outlined,
        onTap: () => _navigateTo('Màn hình Quản lý thành viên trong phòng'),
      ),
    ];
  }

  // --- DANH SÁCH CHỨC NĂNG: TIỆN ÍCH & HỖ TRỢ ---
  List<QuickActionItem> _getUtilityActions(BuildContext context) {
    return [
      QuickActionItem(
        title: 'Báo cáo Sự cố',
        icon: Icons.report_problem_outlined,
        badgeText: '2', // Ví dụ hiển thị số lượng sự cố đang xử lý
        onTap: () => _navigateTo('Màn hình Gửi yêu cầu sửa chữa/sự cố'),
      ),
      QuickActionItem(
        title: 'Thông tin cá nhân',
        icon: Icons.person_outline,
        onTap: () => _navigateTo('Màn hình Cập nhật hồ sơ & thông tin lưu trú'),
      ),
    ];
  }

  void _navigateTo(String featureName) {
    // Thay thế bằng logic điều hướng Navigator.push thực tế của bạn sau này
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Điều hướng đến: $featureName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Đọc trạng thái từ ViewModel của khách thuê (ví dụ: thông tin phòng, thông tin user)
    final viewModel = context.watch<TenantMainLayoutViewModel>();

    final roomActions = _getRoomActions(context,viewModel);
    final utilityActions = _getUtilityActions(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: QUẢN LÝ PHÒNG TRỌ ---
            _buildSectionHeader(
              title: 'Thông tin phòng trọ',
              subtitle: 'Xem thông tin hợp đồng, hóa đơn phòng...',
            ),
            const SizedBox(height: 12),
            _buildGridMenu(roomActions),

            const SizedBox(height: 24),

            // --- SECTION 2: TIỆN ÍCH & HỖ TRỢ ---
            _buildSectionHeader(
              title: 'Tiện ích & Hỗ trợ',
              subtitle: 'Phản ánh sự cố và quản lý tài khoản...',
            ),
            const SizedBox(height: 12),
            _buildGridMenu(utilityActions),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị Tiêu đề phân đoạn nghiệp vụ công việc
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
          icon: Icon(Icons.help_outline, color: Colors.grey[400], size: 22),
          onPressed: () {},
        )
      ],
    );
  }

  // Lưới hiển thị các thẻ Card (Tự động chia 3 cột)
  Widget _buildGridMenu(List<QuickActionItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        return _buildCardItem(items[index]);
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

          // --- XỬ LÝ BADGE THÔNG BÁO GÓC PHẢI ---
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