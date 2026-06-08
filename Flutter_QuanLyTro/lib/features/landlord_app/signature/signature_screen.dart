import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../../core/constants/app_colors.dart';
import 'view_models/signature_view_model.dart';

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  late SignatureController _signatureController;
  final SignatureViewModel _viewModel = SignatureViewModel();

  @override
  void initState() {
    super.initState();
    // Cấu hình bảng vẽ: Nét mực màu xanh nước biển đậm, nền trắng mịn
    _signatureController = SignatureController(
      penStrokeWidth: 4,
      penColor: const Color(0xFF0D47A1),
      exportBackgroundColor: Colors.white,
    );
    _viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
      _viewModel.clearError();
    }
  }

  Future<void> _handleSaveSignature() async {
    // Kiểm tra xem người dùng đã vẽ gì trên bảng chưa
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng vẽ chữ ký của bạn trước khi lưu!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Xuất dữ liệu bảng vẽ thành mảng Bytes định dạng PNG
    final Uint8List? imageBytes = await _signatureController.toPngBytes();

    if (imageBytes != null) {
      final url = await _viewModel.uploadSignature(imageBytes);
      if (url != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thiết lập chữ ký số thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        // Trả về kết quả true để thông báo màn hình chính tải lại thông tin User
        Navigator.pop(context, true);
      }
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Thiết lập Chữ ký số'),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return SafeArea(
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
                        controller: _signatureController,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _viewModel.isLoading ? null : () => _signatureController.clear(),
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
                          onPressed: _viewModel.isLoading ? null : _handleSaveSignature,
                          icon: _viewModel.isLoading
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : const Icon(Icons.check),
                          label: Text(_viewModel.isLoading ? 'Đang lưu...' : 'Xác nhận Lưu'),
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
          );
        },
      ),
    );
  }
}