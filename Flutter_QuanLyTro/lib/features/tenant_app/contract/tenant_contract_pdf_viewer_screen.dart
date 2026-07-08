import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../data/models/response/contract_detail_response.dart';
import 'contract_signature_screen.dart';
import 'view_models/contract_signature_view_model.dart';
import 'view_models/tenant_contract_view_model.dart';

class TenantContractPdfViewerScreen extends StatelessWidget {
  const TenantContractPdfViewerScreen({super.key});

  void _navigateToSignatureScreen(BuildContext context, ContractDetailResponse contract, TenantContractViewModel vm) async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ContractSignatureViewModel(currentContract: contract,areaId: contract.areaId),
          child: const ContractSignatureScreen(),
        ),
      ),
    );

    if (success == true) {
      await vm.loadCurrentContract();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ký hợp đồng thành công!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TenantContractViewModel>();
    final contract = vm.currentContract;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: contract != null ? 'Hợp đồng phòng ${contract.roomNumber}' : 'Chi tiết Hợp đồng',
      ),
      body: _buildBody(vm, contract),

      bottomNavigationBar: _buildBottomNav(context, vm, contract),
    );
  }

  Widget _buildBody(TenantContractViewModel vm, ContractDetailResponse? contract) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (vm.errorMessage != null) {
      return Center(child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)));
    }

    if (contract?.contractFileUrl == null || contract!.contractFileUrl!.isEmpty) {
      return const Center(child: Text('Hợp đồng này chưa có file PDF đính kèm!'));
    }

    return SfPdfViewer.network(
      contract.contractFileUrl!,
    );
  }

  Widget? _buildBottomNav(BuildContext context, TenantContractViewModel vm, ContractDetailResponse? contract) {
    // Ẩn nút nếu đang tải, có lỗi, không có hợp đồng, hoặc ĐÃ KÝ
    if (vm.isLoading || vm.errorMessage != null || contract == null || contract.status == 'SIGNED') {
      return null;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: () => _navigateToSignatureScreen(context, contract, vm),
          icon: const Icon(Icons.draw, color: Colors.white),
          label: const Text(
            'Ký hợp đồng ngay',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}