import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // THÊM IMPORT NÀY
import 'package:signature/signature.dart';
import '../../../core/constants/app_colors.dart';
import 'view_models/signature_view_model.dart';

class SignatureScreen extends StatelessWidget {
  const SignatureScreen({super.key});

  Future<void> _handleSaveSignature(BuildContext context, SignatureViewModel vm) async {
    FocusScope.of(context).unfocus();

    final url = await vm.uploadSignature();

    if (!context.mounted) return;

    if (url != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thiết lập chữ ký số thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      // Trả về kết quả true để thông báo màn hình trước tải lại thông tin User
      Navigator.pop(context, true);
    } else if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
      vm.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe trạng thái từ SignatureViewModel thông qua Provider
    final viewModel = context.watch<SignatureViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Thiết lập Chữ ký số'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ký tên vào khung trống phía dưới:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Signature(
                    controller: viewModel.signatureController,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: viewModel.isLoading ? null : () => viewModel.clearSignature(),
                      icon: const Icon(Icons.clear),
                      label: const Text('Vẽ lại từ đầu'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.redAccent),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: viewModel.isLoading ? null : () => _handleSaveSignature(context, viewModel),
                      icon: viewModel.isLoading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Icon(Icons.check),
                      label: Text(viewModel.isLoading ? 'Đang lưu...' : 'Xác nhận Lưu'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
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