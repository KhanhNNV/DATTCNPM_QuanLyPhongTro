import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../view_models/area_config_view_model.dart';

class ServicesTabWidget extends StatelessWidget {
  final String areaId;
  final AreaConfigViewModel vm;

  const ServicesTabWidget({super.key, required this.areaId, required this.vm});

  String _getCalcTypes(String? calcTypes) {
    switch (calcTypes) {
      case 'PER_PERSON':
        return 'Theo người';
      case 'PER_ROOM':
        return 'Theo phòng';
      case 'BY_INDEX':
        return 'Theo chỉ số';
      default:
        return calcTypes ?? 'Không rõ';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bọc trong Scaffold để thêm nút FloatingActionButton nổi ở góc
    return Scaffold(
      backgroundColor: Colors.transparent, // Giữ nguyên màu nền của Tab
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddServiceDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vm.services.length,
        itemBuilder: (context, index) {
          final service = vm.services[index];
          final serviceIdStr = service['id'].toString();
          final priceController = vm.servicePriceControllers[serviceIdStr];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getCalcTypes(service['calcType']),
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Đơn giá (đ)',
                        suffixText: 'đ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () async {
                        final rawPrice = priceController?.text
                            .replaceAll('.', '')
                            .replaceAll(',', '') ??
                            '0';
                        final success = await vm.saveService(
                            areaId, service['id'], {
                          "name": service['name'],
                          "calcType": service['calcType'],
                          "price": double.tryParse(rawPrice) ?? 0,
                        });

                        if (!context.mounted) return;
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cập nhật giá dịch vụ thành công!'),
                              backgroundColor: Colors.green,
                            ),
                          );
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
                      child: const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- HỘP THOẠI THÊM DỊCH VỤ MỚI ---
  void _showAddServiceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String selectedCalcType = 'PER_PERSON';

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Dùng StatefulBuilder để Dropdown có thể cập nhật trạng thái khi chọn
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Thêm dịch vụ mới'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên dịch vụ (vd: Rác, Internet...)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCalcType,
                      decoration: const InputDecoration(
                        labelText: 'Cách tính',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'PER_PERSON', child: Text('Theo người')),
                        DropdownMenuItem(value: 'PER_ROOM', child: Text('Theo phòng')),
                        DropdownMenuItem(value: 'BY_INDEX', child: Text('Theo chỉ số (Điện/Nước)')),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedCalcType = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Đơn giá',
                        suffixText: 'đ',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập tên dịch vụ!'), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    final payload = {
                      "name": nameController.text.trim(),
                      "calcType": selectedCalcType,
                      "price": double.tryParse(priceController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0,
                    };

                    // Gọi saveService với serviceId = null để tạo mới
                    final success = await vm.saveService(areaId, null, payload);

                    if (!context.mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thêm dịch vụ mới thành công!'), backgroundColor: Colors.green),
                      );
                    } else if (vm.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(vm.errorMessage!), backgroundColor: Colors.redAccent),
                      );
                      vm.clearError();
                    }
                  },
                  child: const Text('Thêm mới'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}