import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  Widget _buildPlaceholderChip(String label, String value, ContractTemplateFormViewModel vm) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      backgroundColor: AppColors.primary.withOpacity(0.08),
      side: const BorderSide(color: AppColors.primary, width: 0.5),
      onPressed: () => vm.insertPlaceholder(value),
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

                  Text(
                    'Các biến tự động điền (Đặt con trỏ và bấm để chèn):',
                    style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPlaceholderChip('👤 Tên khách', '{{TEN_KHACH}}', vm),
                      _buildPlaceholderChip('📞 SĐT', '{{SDT_KHACH}}', vm),
                      _buildPlaceholderChip('🪪 CCCD', '{{CCCD_KHACH}}', vm),
                      _buildPlaceholderChip('🚪 Tên phòng', '{{TEN_PHONG}}', vm),
                      _buildPlaceholderChip('💵 Giá thuê', '{{GIA_THUE}}', vm),
                      _buildPlaceholderChip('🛡️ Tiền cọc', '{{TIEN_COC}}', vm),
                      _buildPlaceholderChip('📅 Ngày BĐ', '{{NGAY_BAT_DAU}}', vm),
                    ],
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: vm.contentController,
                    maxLines: 18,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                    decoration: InputDecoration(
                      labelText: 'Nội dung điều khoản điều lệ',
                      alignLabelWithHint: true,
                      hintText: 'Nhập nội dung chi tiết hợp đồng tại đây...\nSử dụng các biến trợ lý phía trên để tự động điền dữ liệu động khi lập hợp đồng thật.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Vui lòng nhập nội dung hợp đồng';
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

// --- MÀN HÌNH MÔ PHỎNG VĂN BẢN TRÊN KHUNG GIẤY TRẮNG TRONG APP ---
class _InAppPreviewScreen extends StatelessWidget {
  final ContractTemplateFormViewModel vm;

  const _InAppPreviewScreen({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Bản xem trước hợp đồng', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: () async {
              try {
                await vm.previewPdf();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.orange),
                );
              }
            },
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
            label: const Text('XUẤT PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Column(
                  children: [
                    Text('CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM',textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                    SizedBox(height: 2),
                    Text('Độc lập – Tự do – Hạnh phúc',textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                    SizedBox(height: 4),
                    SizedBox(width: 140, child: Divider(color: Colors.black, thickness: 1, height: 1)),
                  ],
                ),
                const SizedBox(height: 28),

                Text(
                  vm.nameController.text.isNotEmpty
                      ? vm.nameController.text.toUpperCase()
                      : 'HỢP ĐỒNG THUÊ PHÒNG TRỌ',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 24),

                const Text('Hôm nay, ngày 22 tháng 06 năm 2026, tại căn nhà số: 123 Đường ABC, Phường X, Quận Y. Chúng tôi gồm có:', style: TextStyle(fontSize: 12,fontStyle: FontStyle.italic, color: Colors.black87)),
                const SizedBox(height: 12),

                const Text('BÊN CHO THUÊ PHÒNG TRỌ (gọi tắt là Bên A):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const Text('Ông/bà: TRẦN VĂN CHỦ'),
                const Text('CMND/CCCD số: 079090000123   cấp ngày: 01/01/2021   nơi cấp: Cục Cảnh sát QLHC về TTXH'),
                const Text('Thường trú tại: 123 Đường ABC, Phường X, Quận Y, TP.HCM'),
                const SizedBox(height: 12),

                const Text('BÊN THUÊ PHÒNG TRỌ (gọi tắt là Bên B):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const Text('Ông/bà: NGUYỄN VĂN A'),
                const Text('CMND/CCCD số: 001095001234   cấp ngày: 15/05/2022   nơi cấp: Cục Cảnh sát QLHC về TTXH'),
                const Text('Thường trú tại: 456 Đường DEF, Phường Z, Quận W, TP.HCM'),
                const SizedBox(height: 16),

                const Text('Sau khi thỏa thuận, hai bên thống nhất như sau:', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),

                Text(
                  vm.simulatedPreviewText,
                  style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 36),

                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Bên B', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('(Ký, ghi rõ họ tên)', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54)),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Bên A', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('(Ký, ghi rõ họ tên)', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}