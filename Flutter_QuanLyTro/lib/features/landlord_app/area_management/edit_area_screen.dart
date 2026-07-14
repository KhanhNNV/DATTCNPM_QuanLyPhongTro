import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/response/area_model.dart';
import '../onboarding/widgets/general_info_card.dart';
import 'view_models/edit_area_view_model.dart';

class EditAreaScreen extends StatelessWidget {
  final AreaModel area;

  const EditAreaScreen({
    super.key,
    required this.area,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Chỉnh sửa Khu trọ'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<EditAreaViewModel>(
        builder: (context, vm, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0, left: 4.0),
                  child: Text(
                    'Thông tin cơ bản',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                GeneralInfoCard(
                  nameController: vm.nameController,
                  addressController: vm.addressController,
                  invoiceDay: vm.invoiceDay,
                  dueDate: vm.dueDate,
                  onInvoiceDayChanged: (val) {
                    if (val != null) vm.updateInvoiceDay(val);
                  },
                  onDueDateChanged: (val) {
                    if (val != null) vm.updateDueDate(val);
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: vm.isLoading
                      ? null
                      : () async {

                    final success = await vm.updateAreaInfo(area.id);


                    if (!context.mounted) return;

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Cập nhật thông tin khu trọ thành công"),
                          backgroundColor: Colors.green,
                        ),
                      );
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
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: vm.isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Text(
                    'Lưu thay đổi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}