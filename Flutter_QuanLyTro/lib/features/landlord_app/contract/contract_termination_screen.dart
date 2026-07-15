import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quanlytro/features/landlord_app/contract/view_models/contract_termination_view_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../data/models/response/contract_termination_response.dart';

class ContractTerminationScreen extends StatelessWidget {
  const ContractTerminationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ContractTerminationViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Trả phòng & Thanh lý'),
      body: viewModel.isLoading && viewModel.activeContracts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (viewModel.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(viewModel.errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            const Text(
              '1. Chọn phòng cần thanh lý',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF263238)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              hint: const Text('Chọn phòng...'),
              value: viewModel.selectedContractId,
              items: viewModel.activeContracts.map((contract) {
                return DropdownMenuItem(
                  value: contract.id,
                  child: Text(
                    'Phòng ${contract.roomNumber} - Khách: ${contract.tenantName ?? 'N/A'}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: viewModel.selectContract,
            ),
            const SizedBox(height: 24),
            const Text(
              '2. Chốt chỉ số tháng cuối (nếu có)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF263238)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Nhập số điện/nước đã sử dụng trong tháng cuối để tự động trừ vào tiền cọc.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: viewModel.electricityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'Số ĐIỆN sử dụng',
                suffixText: 'kWh',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: viewModel.waterController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'Số NƯỚC sử dụng',
                suffixText: 'Khối',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: viewModel.isLoading
                    ? null
                    : () async {
                  final response = await context.read<ContractTerminationViewModel>().submitTermination();
                  if (response != null && context.mounted) {
                    _showResultDialog(context, response);
                  }
                },
                child: viewModel.isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text(
                  'Xác nhận Thanh lý Hợp đồng',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showResultDialog(BuildContext context, ContractTerminationResponse response) {
    String actionText = '';
    Color actionColor = Colors.black;

    if (response.settlementAction == 'HOÀN_TRẢ_KHÁCH') {
      actionText = 'Cần hoàn trả cho khách';
      actionColor = Colors.green;
    } else if (response.settlementAction == 'THU_THÊM_TỪ_KHÁCH') {
      actionText = 'Khách cần đóng thêm';
      actionColor = Colors.red;
    } else {
      actionText = 'Hòa công nợ';
      actionColor = Colors.orange;
    }

    String formatMoney(double amount) {
      return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('Thanh lý thành công', style: TextStyle(fontSize: 18))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phòng: ${response.roomNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text('Tiền cọc ban đầu:', style: TextStyle(fontSize: 15)),
                  ),
                  Text(
                    formatMoney(response.depositAmount),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text('Tổng trừ (Phòng + Điện + Nước + (Phí DV khác)):', style: TextStyle(color: Colors.red, fontSize: 15)),
                  ),
                  Text(
                    '- ${formatMoney(response.totalDeduction)}',
                    style: const TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(actionText, style: TextStyle(color: actionColor, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                formatMoney(response.finalAmount),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: actionColor),
              )
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Đóng', style: TextStyle(fontSize: 16)),
          )
        ],
      ),
    );
  }
}