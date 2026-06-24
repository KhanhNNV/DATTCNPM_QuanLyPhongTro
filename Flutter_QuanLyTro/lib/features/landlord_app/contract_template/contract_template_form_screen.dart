import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';

import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/constants/app_colors.dart';
import 'view_models/contract_template_form_view_model.dart';

class ContractTemplateFormScreen extends StatelessWidget {
  const ContractTemplateFormScreen({super.key});

  Future<void> _handleSave(BuildContext context, ContractTemplateFormViewModel vm) async {
    FocusScope.of(context).unfocus();
    try {
      final newTemplate = await vm.saveTemplate();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo mẫu hợp đồng thành công'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, newTemplate);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _handleShowInAppPreview(BuildContext context, ContractTemplateFormViewModel vm) {
    if (vm.contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung điều khoản trước!'), backgroundColor: Colors.orange),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _InAppPreviewScreen(vm: vm)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ContractTemplateFormViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Tạo mẫu hợp đồng'),
      body: Form(
        key: vm.formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                children: [
                  TextFormField(
                    controller: vm.nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên mẫu hợp đồng',
                      hintText: 'VD: Mẫu hợp đồng chuẩn năm 2026',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Vui lòng nhập tên mẫu';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  TextFormField(
                    controller: vm.contentController,
                    maxLines: 20,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                    decoration: InputDecoration(
                      labelText: 'Nội dung điều khoản hợp đồng',
                      alignLabelWithHint: true,
                      hintText: 'Nhập nội dung chi tiết các điều khoản tại đây...\nCác thông tin Bên A, Bên B sẽ được hệ thống tự động chèn vào phần đầu của hợp đồng.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Vui lòng nhập nội dung điều khoản';
                      return null;
                    },
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 8)
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: vm.isLoading ? null : () => _handleShowInAppPreview(context, vm),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            foregroundColor: AppColors.primary,
                          ),
                          icon: const Icon(Icons.remove_red_eye_outlined, size: 20),
                          label: const Text('XEM TRƯỚC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: SizedBox(
                        height: 48,
                        child: CustomButton(
                          text: 'LƯU MẪU HỢP ĐỒNG',
                          isLoading: vm.isLoading,
                          onPressed: () => _handleSave(context, vm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- MÀN HÌNH XEM TRƯỚC ---
class _InAppPreviewScreen extends StatefulWidget {
  final ContractTemplateFormViewModel vm;

  const _InAppPreviewScreen({required this.vm});

  @override
  State<_InAppPreviewScreen> createState() => _InAppPreviewScreenState();
}

class _InAppPreviewScreenState extends State<_InAppPreviewScreen> {
  late Future<Uint8List> _pdfBytesFuture;
  Uint8List? _cachedBytes;

  @override
  void initState() {
    super.initState();
    _pdfBytesFuture = widget.vm.generatePdfBytes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Bản xem trước hợp đồng', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: _cachedBytes == null
                ? null
                : () async {
              try {
                await FileSaver.instance.saveAs(
                  name: 'Hop_Dong_Thue_Phong_${DateTime.now().millisecondsSinceEpoch}.pdf',
                  bytes: _cachedBytes!,
                  mimeType: MimeType.pdf,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xuất file PDF thành công!'), backgroundColor: Colors.green),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi xuất file: $e'), backgroundColor: Colors.redAccent),
                );
              }
            },
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
            label: const Text('XUẤT PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfBytesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Không thể khởi tạo bản xem trước PDF:\n${snapshot.error.toString().replaceAll('Exception: ', '')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ),
            );
          }
          if (snapshot.hasData) {
            _cachedBytes = snapshot.data;
            return SfPdfViewer.memory(
              _cachedBytes!,
              canShowScrollHead: true,
              canShowScrollStatus: true,
            );
          }
          return const Center(child: Text('Không có dữ liệu văn bản.'));
        },
      ),
    );
  }
}