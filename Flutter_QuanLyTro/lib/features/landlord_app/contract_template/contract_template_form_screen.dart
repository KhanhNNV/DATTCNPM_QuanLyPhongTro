import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/constants/app_colors.dart';
import 'view_models/contract_template_form_view_model.dart';
import 'contract_template_preview_screen.dart';

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
    if (vm.rentalContentController.text.trim().isEmpty &&
        vm.landlordDutyController.text.trim().isEmpty &&
        vm.tenantDutyController.text.trim().isEmpty &&
        vm.executionTermsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung điều khoản trước khi xem trước!'), backgroundColor: Colors.orange),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractTemplatePreviewScreen(
          templateName: vm.nameController.text.trim(),
          rentalContent: vm.rentalContentController.text.trim(),
          landlordDuty: vm.landlordDutyController.text.trim(),
          tenantDuty: vm.tenantDutyController.text.trim(),
          executionTerms: vm.executionTermsController.text.trim(),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, int lines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(fontSize: 14, height: 1.4),
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập $label' : null,
      ),
    );
  }

  Widget _buildVariablesGuide() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: ExpansionTile(
        title: const Text(
          'Hướng dẫn dùng biến tự động điền (Nhấn để xem)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        iconColor: Colors.blue,
        collapsedIconColor: Colors.blue,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'Khi tạo hợp đồng thực tế, hệ thống sẽ tự động điền dữ liệu vào các mã có ngoặc nhọn {{...}} dưới đây. Bạn có thể chèn các mã này vào bất cứ đâu trong nội dung hợp đồng:\n\n'
                  '• {{SO_PHONG}}: Số phòng/Tên phòng\n'
                  '• {{DIA_CHI_NHA}}: Địa chỉ nhà trọ\n'
                  '• {{THOI_HAN}}: Thời gian thuê (tháng)\n'
                  '• {{GIA_THUE}}: Giá thuê (số)\n'
                  '• {{GIA_THUE_CHU}}: Giá thuê (chữ)\n'
                  '• {{TIEN_COC}}: Tiền đặt cọc (số)\n'
                  '• {{TIEN_COC_CHU}}: Tiền đặt cọc (chữ)\n'
                  '• {{NGAY_THANH_TOAN}}: Ngày đóng tiền hàng tháng',
              style: TextStyle(fontSize: 13, height: 1.5, color: Colors.blue[900]),
            ),
          ),
        ],
      ),
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
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập tên mẫu' : null,
                  ),
                  const SizedBox(height: 24),

                  _buildVariablesGuide(),

                  const Text(
                      'Tùy chỉnh nội dung điều khoản:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(vm.rentalContentController, '1. Nội dung thuê phòng trọ', 4),
                  _buildTextField(vm.landlordDutyController, '2. Trách nhiệm Bên A', 4),
                  _buildTextField(vm.tenantDutyController, '3. Trách nhiệm Bên B', 8),
                  _buildTextField(vm.executionTermsController, '4. Điều khoản thực hiện', 4),
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