import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../data/models/response/contract_detail_response.dart';
import '../main_layout/view_models/main_layout_view_model.dart';
import 'contract_pdf_viewer_screen.dart';
import 'contract_update_screen.dart';
import 'view_models/contract_list_view_model.dart';
import 'view_models/contract_update_view_model.dart';
import 'view_models/contract_extend_view_model.dart';

class ContractListScreen extends StatelessWidget {
  const ContractListScreen({super.key});

  String _formatDate(String dateStr) {
    try {
      final parsedDate = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (_) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DRAFT':
        return Colors.orange;
      case 'SIGNED':
        return Colors.green;
      case 'EXPIRED':
        return Colors.red;
      case 'TERMINATED':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  void _showDeleteConfirmDialog(BuildContext context, ContractListViewModel vm, ContractDetailResponse contract) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa hợp đồng?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa hợp đồng phòng ${contract.roomNumber} không? Dữ liệu không thể khôi phục.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final message = await vm.deleteContract(contract.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Xóa ngay'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEditContract(BuildContext context, ContractListViewModel vm, ContractDetailResponse contract) async {
    final currentAreaId = context.read<MainLayoutViewModel>().selectedAreaId;

    if (currentAreaId == null || currentAreaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Chưa xác định được Khu trọ hiện tại!')),
      );
      return;
    }

    final isUpdated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ContractUpdateViewModel(currentContract: contract, areaId: currentAreaId),
          child: const ContractUpdateScreen(),
        ),
      ),
    );

    if (isUpdated == true) {
      vm.fetchContracts();
    }
  }

  // HÀM XỬ LÝ GIA HẠN HỢP ĐỒNG
  void _handleExtendContract(BuildContext context, ContractListViewModel listVm, ContractDetailResponse contract) {
    final currentAreaId = context.read<MainLayoutViewModel>().selectedAreaId;
    if (currentAreaId == null || currentAreaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Chưa xác định được Khu trọ hiện tại!')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ChangeNotifierProvider(
          create: (_) => ContractExtendViewModel(),
          child: Consumer<ContractExtendViewModel>(
            builder: (ctx, extendVm, child) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: const Text('Gia hạn hợp đồng', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chọn ngày kết thúc mới cho phòng ${contract.roomNumber}:'),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        DateTime oldEndDate = DateTime.parse(contract.endDate);
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: extendVm.newEndDate ?? oldEndDate.add(const Duration(days: 180)), // Mặc định +6 tháng
                          firstDate: oldEndDate.add(const Duration(days: 1)),
                          lastDate: DateTime(2100),
                          helpText: 'CHỌN NGÀY KẾT THÚC MỚI',
                        );
                        if (picked != null) extendVm.changeNewEndDate(picked);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              extendVm.newEndDate == null
                                  ? 'Nhấn để chọn ngày'
                                  : DateFormat('dd/MM/yyyy').format(extendVm.newEndDate!),
                              style: TextStyle(
                                color: extendVm.newEndDate == null ? Colors.grey[600] : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    if (extendVm.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(extendVm.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ]
                  ],
                ),
                actions: [
                  if (extendVm.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(right: 16.0, bottom: 8.0),
                      child: SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                    )
                  else ...[
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final success = await extendVm.submitExtendContract(
                          oldContractId: contract.id,
                          currentAreaId: currentAreaId,
                        );
                        if (success && ctx.mounted) {
                          Navigator.pop(ctx, true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gia hạn hợp đồng thành công!'), backgroundColor: Colors.green),
                          );
                        }
                      },
                      child: const Text('Xác nhận'),
                    ),
                  ]
                ],
              );
            },
          ),
        );
      },
    ).then((isSuccess) {
      if (isSuccess == true) {
        listVm.fetchContracts(); // Gọi lại API reload danh sách
      }
    });
  }

  void _showActionSheet(BuildContext context, ContractListViewModel vm, ContractDetailResponse contract) {
    final canEdit = contract.status == 'DRAFT';
    final canDelete = contract.status == 'DRAFT' || contract.status == 'EXPIRED';
    final canExtend = contract.status == 'SIGNED' || contract.status == 'EXPIRED';

    if (!canEdit && !canDelete && !canExtend) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canExtend)
                ListTile(
                  leading: const Icon(Icons.autorenew, color: Colors.green),
                  title: const Text('Gia hạn hợp đồng'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _handleExtendContract(context, vm, contract);
                  },
                ),
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                  title: const Text('Sửa hợp đồng'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _handleEditContract(context, vm, contract);
                  },
                ),
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Xóa hợp đồng'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showDeleteConfirmDialog(context, vm, contract);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ContractListViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: const CustomAppBar(title: 'Quản lý hợp đồng'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: vm.searchController,
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
          final fileUrl = contract.contractFileUrl;
          if (fileUrl != null && fileUrl.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ContractPdfViewerScreen(
                  pdfUrl: fileUrl,
                  roomNumber: contract.roomNumber,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hợp đồng này chưa có file đính kèm!')),
            );
          }
        },
        onLongPress: () => _showActionSheet(context, vm, contract),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      vm.statusMap[contract.status] ?? contract.status,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 0.5),
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