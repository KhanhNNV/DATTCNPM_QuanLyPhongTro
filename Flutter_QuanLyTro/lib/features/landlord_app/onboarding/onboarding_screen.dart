import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/landlord_app/onboarding/view_models/onboarding_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../home_page/home_page_screen.dart';
import 'models/onboarding_models.dart';
import 'widgets/general_info_card.dart';
import 'widgets/services_card.dart';
import 'widgets/default_room_card.dart';
import 'widgets/dynamic_floor_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final OnboardingViewModel _viewModel = OnboardingViewModel();
  // --- 1. STATE THÔNG TIN KHU TRỌ ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  int _invoiceDay = 1;
  int _dueDate = 5;

  // --- 2. STATE PHÒNG MẪU ---
  final TextEditingController _areaSizeController = TextEditingController();
  final TextEditingController _rentPriceController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();
  final TextEditingController _maxOccupantsController = TextEditingController();

  // --- 3. STATE DỊCH VỤ ---
  final List<AppServiceItem> _services = [
    AppServiceItem(name: 'Điện', calcType: ServiceCalculationType.byIndex),
    AppServiceItem(name: 'Nước', calcType: ServiceCalculationType.byIndex),
    AppServiceItem(name: 'Rác', calcType: ServiceCalculationType.perPerson),
    AppServiceItem(name: 'Wifi', calcType: ServiceCalculationType.perRoom),
  ];

  // --- 4. STATE TẦNG ĐỘNG ---
  final TextEditingController _floorCountController = TextEditingController();
  int _floorCount = 0;
  final List<TextEditingController> _roomsPerFloorControllers = [];


  @override
  void initState() {
    super.initState();
    // Lắng nghe lỗi từ ViewModel để hiện SnackBar
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

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _areaSizeController.dispose();
    _rentPriceController.dispose();
    _depositController.dispose();
    _maxOccupantsController.dispose();
    _floorCountController.dispose();
    for (var controller in _roomsPerFloorControllers) {
      controller.dispose();
    }
    for (var service in _services) {
      service.priceController.dispose();
    }
    super.dispose();
  }

  void _updateFloorCount(String value) {
    int? newCount = int.tryParse(value);
    if (newCount == null || newCount < 0) newCount = 0;
    if (newCount > 50) newCount = 50;

    setState(() {
      _floorCount = newCount!;
      if (_roomsPerFloorControllers.length < _floorCount) {
        for (int i = _roomsPerFloorControllers.length; i < _floorCount; i++) {
          _roomsPerFloorControllers.add(TextEditingController(text: '10'));
        }
      } else if (_roomsPerFloorControllers.length > _floorCount) {
        for (int i = _roomsPerFloorControllers.length - 1; i >= _floorCount; i--) {
          _roomsPerFloorControllers[i].dispose();
          _roomsPerFloorControllers.removeAt(i);
        }
      }
    });
  }

// --- HÀM SUBMIT GỌI VIEWMODEL ---
  void _submitData() {
    // Gom danh sách số lượng phòng mỗi tầng
    List<int> roomsPerFloor = _roomsPerFloorControllers
        .map((controller) => int.tryParse(controller.text) ?? 0)
        .toList();

    // Gom danh sách dịch vụ
    List<Map<String, dynamic>> servicesPayload = _services.map((s) {
      return {
        'name': s.name,
        'calcType': s.calcType.backendValue,
        'price': num.tryParse(s.priceController.text) ?? 0,
      };
    }).toList();

    // Đóng gói toàn bộ thành JSON
    final payload = {
      "name": _nameController.text.trim(),
      "address": _addressController.text.trim(),
      "invoiceDay": _invoiceDay,
      "dueDate": _dueDate,
      "services": servicesPayload,
      "roomsPerFloor": roomsPerFloor,
      "defaultAreaSize": double.tryParse(_areaSizeController.text) ?? 0.0,
      "defaultRentPrice": double.tryParse(_rentPriceController.text) ?? 0.0,
      "defaultDepositAmount": double.tryParse(_depositController.text) ?? 0.0,
      "defaultMaxOccupants": int.tryParse(_maxOccupantsController.text) ?? 1,
    };

    // 4. Gọi hàm từ ViewModel
    _viewModel.submitOnboarding(
      payload: payload,
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Khởi tạo Khu trọ thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePageScreen()),
        );
      },
    );
  }

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('1. Thông tin chung'),
            GeneralInfoCard(
              nameController: _nameController,
              addressController: _addressController,
              invoiceDay: _invoiceDay,
              dueDate: _dueDate,
              onInvoiceDayChanged: (val) => setState(() => _invoiceDay = val!),
              onDueDateChanged: (val) => setState(() => _dueDate = val!),
            ),

            const SizedBox(height: 20),
            _buildSectionTitle('2. Cấu hình dịch vụ cơ bản'),
            ServicesCard(
              services: _services,
              onServiceTypeChanged: () => setState(() {}), // Refresh UI để cập nhật hậu tố đơn vị
            ),

            const SizedBox(height: 20),
            _buildSectionTitle('3. Cấu hình phòng mẫu'),
            DefaultRoomCard(
              rentPriceController: _rentPriceController,
              depositController: _depositController,
              areaSizeController: _areaSizeController,
              maxOccupantsController: _maxOccupantsController,
            ),

            const SizedBox(height: 20),
            _buildSectionTitle('4. Cấu hình số lượng phòng'),
            DynamicFloorCard(
              floorCountController: _floorCountController,
              floorCount: _floorCount,
              roomsPerFloorControllers: _roomsPerFloorControllers,
              onFloorCountChanged: _updateFloorCount,
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Hoàn tất khởi tạo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }
}