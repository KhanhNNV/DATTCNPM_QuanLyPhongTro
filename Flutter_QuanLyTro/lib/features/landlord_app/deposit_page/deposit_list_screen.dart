import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../data/models/response/deposit_response.dart';
import 'view_models/deposit_detail_view_model.dart';
import 'view_models/deposit_form_view_model.dart';
import 'deposit_detail_screen.dart';
import 'view_models/deposit_list_view_model.dart';
import 'deposit_form_screen.dart';

class DepositListScreen extends StatelessWidget {
  final String areaId;

  const DepositListScreen({super.key, required this.areaId});

  String _formatCurrency(double amount) {
    return NumberFormat('#,###', 'vi_VN').format(amount).replaceAll(',', '.');
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'COMPLETED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DepositListViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Quản lý Đặt cọc'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (_) => DepositFormViewModel()..loadRooms(areaId),
                child: const DepositFormScreen(),
              ),
            ),
          );


          //bắt kết quả trả về từ Navigator.push
          if (context.mounted) {
            if (result is DepositResponse) {
              // Nếu trang Tạo mới trả về object -> Thêm luôn vào List
              context.read<DepositListViewModel>().addLocalDeposit(result);
            } else if (result == true) {
              // Fallback an toàn (trường hợp form chỉ trả về true)
              context.read<DepositListViewModel>().fetchDeposits(areaId);
            }
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      // Bọc _buildBody trong Column để chứa cả phần Search & Filter
      body: Column(
        children: [
          _buildSearchAndFilter(context, vm),
          Expanded(child: _buildBody(vm, context)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context, DepositListViewModel vm) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thanh tìm kiếm
          TextField(
            onChanged: vm.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, số điện thoại...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Thanh chọn trạng thái
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: vm.statusMap.entries.map((entry) {
                final isSelected = vm.selectedStatus == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey[100],
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                    onSelected: (_) => vm.changeStatus(entry.key, areaId),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
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
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => vm.fetchDeposits(areaId),
              child: const Text('Thử lại'),
            )
          ],
        ),
      );
    }

    // Đổi kiểm tra vm.deposits sang vm.displayedDeposits
    if (vm.displayedDeposits.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy phiếu đặt cọc nào.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vm.displayedDeposits.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final deposit = vm.displayedDeposits[index];
        final statusColor = _getStatusColor(deposit.status);

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

            // xử lý kết quả trả về từ màn detail
            if (context.mounted && result != null) {
              if (result == 'deleted') {
                // Nếu báo đã xóa -> Xóa cục bộ
                context.read<DepositListViewModel>().deleteLocalDeposit(deposit.id);
              } else if (result is DepositResponse) {
                // Nếu trả về object -> Cập nhật cục bộ
                context.read<DepositListViewModel>().updateLocalDeposit(result);
              } else if (result == true) {
                // Fallback an toàn
                context.read<DepositListViewModel>().fetchDeposits(areaId);
              }
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
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          vm.statusMap[deposit.status] ?? deposit.status, // Hiện text tiếng Việt
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
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
          ),
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