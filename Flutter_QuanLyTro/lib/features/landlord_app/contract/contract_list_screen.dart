import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../data/models/response/contract_detail_response.dart';
import 'view_models/contract_list_view_model.dart';

class ContractListScreen extends StatelessWidget {
  const ContractListScreen({super.key});

  // Định dạng hiển thị ngày DD/MM/YYYY từ String yyyy-MM-dd của Backend
  String _formatDate(String dateStr) {
    try {
      final parsedDate = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (_) {
      return dateStr;
    }
  }

  // Trả về màu sắc tương ứng với từng trạng thái hợp đồng
  Color _getStatusColor(String status) {
    switch (status) {
      case 'DRAFT': return Colors.orange; // Bản nháp: Màu cam
      case 'SIGNED': return Colors.green; // Đã ký: Màu xanh lá
      case 'EXPIRED': return Colors.red;  // Hết hạn: Màu đỏ
      case 'TERMINATED': return Colors.grey; // Thanh lý: Màu xám
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe State được cung cấp từ màn hình cha
    final vm = context.watch<ContractListViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: const CustomAppBar(title: 'Quản lý hợp đồng'),
      body: Column(
        children: [
          // 1. THANH TÌM KIẾM
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: vm.searchController, // Lấy Controller từ ViewModel
              onChanged: vm.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm theo số phòng, tên khách thuê...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
          ),

          // 2. CHIPS PHÂN LOẠI TRẠNG THÁI
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: vm.statusMap.entries.map((entry) {
                final isSelected = vm.selectedStatus == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    onSelected: (_) => vm.changeStatus(entry.key),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.grey[300]!,
                      width: 0.8,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 3. DANH SÁCH HỢP ĐỒNG
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : vm.errorMessage != null
                ? Center(child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)))
                : vm.displayedContracts.isEmpty
                ? const Center(child: Text('Không tìm thấy dữ liệu hợp đồng nào!'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: vm.displayedContracts.length,
              itemBuilder: (context, index) {
                final contract = vm.displayedContracts[index];
                return _buildContractCard(context, vm, contract);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget Thẻ chi tiết hợp đồng rút gọn
  Widget _buildContractCard(BuildContext context, ContractListViewModel vm, ContractDetailResponse contract) {
    final statusColor = _getStatusColor(contract.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // CHUYỂN SANG MÀN HÌNH CHI TIẾT
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Xem chi tiết hợp đồng phòng: ${contract.roomNumber}')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng đầu tiên: Số phòng và Trạng thái
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.door_back_door, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Phòng ${contract.roomNumber}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      vm.statusMap[contract.status] ?? contract.status,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 0.5),

              // Hàng thứ hai: Khách thuê đại diện
              Row(
                children: [
                  Icon(Icons.person_outline, color: Colors.grey[600], size: 18),
                  const SizedBox(width: 8),
                  const Text('Khách thuê: ', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text(
                    contract.tenantName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF263238)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Hàng thứ ba: Ngày hiệu lực (Bắt đầu -> Kết thúc)
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  const Text('Thời hạn: ', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text(
                    '${_formatDate(contract.startDate)} - ${_formatDate(contract.endDate)}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF263238)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}