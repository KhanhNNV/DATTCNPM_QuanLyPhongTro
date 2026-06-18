import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../main_layout/main_layout_screen.dart';
import 'view_models/onboarding_view_model.dart';
import 'widgets/general_info_card.dart';
import 'widgets/services_card.dart';
import 'widgets/default_room_card.dart';
import 'widgets/dynamic_floor_card.dart';

class OnboardingScreen extends StatelessWidget {
  final bool isAddingNewArea;

  const OnboardingScreen({
    super.key,
    this.isAddingNewArea = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Khởi tạo Khu trọ'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      // --- Lắng nghe trạng thái từ ViewModel ---
      body: Consumer<OnboardingViewModel>(
        builder: (context, vm, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('1. Thông tin chung'),
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
                const SizedBox(height: 20),

                _buildSectionTitle('2. Cấu hình dịch vụ cơ bản'),
                ServicesCard(
                  services: vm.services,
                  onServiceTypeChanged: () => vm.updateServiceType(),
                ),
                const SizedBox(height: 20),

                _buildSectionTitle('3. Cấu hình phòng mẫu'),
                DefaultRoomCard(
                  rentPriceController: vm.rentPriceController,
                  depositController: vm.depositController,
                  areaSizeController: vm.areaSizeController,
                  maxOccupantsController: vm.maxOccupantsController,
                ),
                const SizedBox(height: 20),

                _buildSectionTitle('4. Cấu hình số lượng phòng'),
                DynamicFloorCard(
                  floorCountController: vm.floorCountController,
                  floorCount: vm.floorCount,
                  roomsPerFloorControllers: vm.roomsPerFloorControllers,
                  onFloorCountChanged: vm.updateFloorCount,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: vm.isLoading
                      ? null
                      : () async {
                    // Lấy kết quả từ ViewModel thay vì truyền Callback
                    final newArea = await vm.submitOnboarding();

                    if (!context.mounted) return;

                    if (newArea != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Khởi tạo Khu trọ thành công!'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      if (isAddingNewArea) {
                        Navigator.pop(context, newArea);
                      } else {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainLayoutScreen(),
                          ),
                              (route) => false,
                        );
                      }
                    } else if (vm.errorMessage != null) {
                      // Xử lý báo lỗi ngay tại UI
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
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: vm.isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                      : const Text(
                    'Hoàn tất khởi tạo',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }
}