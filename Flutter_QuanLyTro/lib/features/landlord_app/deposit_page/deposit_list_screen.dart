import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/landlord_app/deposit_page/view_models/deposit_detail_view_model.dart';
import 'package:flutter_quanlytro/features/landlord_app/deposit_page/view_models/deposit_form_view_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import 'deposit_detail_screen.dart';
import 'view_models/deposit_list_view_model.dart';
import 'deposit_form_screen.dart';

class DepositListScreen extends StatelessWidget {
  final String areaId;

  const DepositListScreen({super.key, required this.areaId});

  String _formatCurrency(double amount) {
    return NumberFormat('#,###', 'vi_VN').format(amount).replaceAll(',', '.');
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ cần watch để lắng nghe data
    final vm = context.watch<DepositListViewModel>();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Quản lý Đặt cọc'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          // Sang trang thêm cọc
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (_) => DepositFormViewModel()..loadRooms(areaId),
                child: const DepositFormScreen(),
              ),
            ),
          );

          // Nếu có phiếu cọc mới được tạo, gọi lại hàm fetch để cập nhật list
          if (result == true && context.mounted) {
            context.read<DepositListViewModel>().fetchDeposits(areaId);
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _buildBody(vm, context),
    );
  }

  Widget _buildBody(DepositListViewModel vm, BuildContext context) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: () => vm.fetchDeposits(areaId),
              child: const Text('Thử lại'),
            )
          ],
        ),
      );
    }

    if (vm.deposits.isEmpty) {
      return const Center(
        child: Text('Chưa có phiếu đặt cọc nào.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vm.deposits.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final deposit = vm.deposits[index];
        return InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                    create: (_) => DepositDetailViewModel()..initData(deposit),
                    child: const DepositDetailScreen(),
                  ),
                ),
              );

              if (result == true && context.mounted) {
                context.read<DepositListViewModel>().fetchDeposits(areaId);
              }
            },
            borderRadius: BorderRadius.circular(12),
          child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Phòng ${deposit.roomNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        deposit.status,
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow(Icons.person, 'Khách thuê:', deposit.tenantFullName),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone, 'Số điện thoại:', deposit.phone),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.monetization_on, 'Tiền cọc:', '${_formatCurrency(deposit.depositAmount)} VNĐ', isHighlight: true),
              ],
            ),
          ),
          )
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? Colors.redAccent : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}