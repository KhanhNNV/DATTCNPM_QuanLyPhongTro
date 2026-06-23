import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/response/contract_template_response.dart';
import 'view_models/contract_template_list_view_model.dart';
import 'view_models/contract_template_form_view_model.dart';
import 'contract_template_form_screen.dart';

class ContractTemplateListScreen extends StatefulWidget {
  const ContractTemplateListScreen({super.key});

  @override
  State<ContractTemplateListScreen> createState() => _ContractTemplateListScreenState();
}

class _ContractTemplateListScreenState extends State<ContractTemplateListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Gọi API giả lập khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContractTemplateListViewModel>().fetchTemplates();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Popup hiển thị chi tiết nội dung mẫu hợp đồng
  void _showTemplateDetails(BuildContext context, ContractTemplateResponse template) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          template.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Text(
            template.content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ĐÓNG'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ContractTemplateListViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Chọn mẫu hợp đồng'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (_) => ContractTemplateFormViewModel(),
                child: const ContractTemplateFormScreen(),
              ),
            ),
          ).then((newTemplate) {
            // Nhận kết quả trả về khi tạo xong (Nếu có)
            // if (newTemplate != null) vm.addLocalTemplate(newTemplate);
          });
        },
        child: const Icon(Icons.add, color: Colors.white)
      ),
      body: Column(
        children: [
          // KHUNG TÌM KIẾM
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: vm.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tên mẫu hợp đồng...',
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

          // DANH SÁCH LIST DẠNG RADIO
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : vm.errorMessage != null
                ? Center(child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)))
                : vm.displayedTemplates.isEmpty
                ? const Center(child: Text('Không tìm thấy mẫu hợp đồng nào!'))
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), // Padding bottom tránh đè FAB
              itemCount: vm.displayedTemplates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final template = vm.displayedTemplates[index];
                final isSelected = vm.selectedTemplateId == template.id;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.grey[300]!,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => vm.selectTemplate(template.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: template.id,
                            groupValue: vm.selectedTemplateId,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              if (val != null) vm.selectTemplate(val);
                            },
                          ),
                          Expanded(
                            child: Text(
                              template.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primary : Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_red_eye, color: Colors.grey),
                            tooltip: 'Xem chi tiết',
                            onPressed: () => _showTemplateDetails(context, template),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}