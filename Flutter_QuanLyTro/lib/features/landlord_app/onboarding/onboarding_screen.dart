import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

// --- ĐỊNH NGHĨA ENUM ĐỂ MAP VỚI BACKEND ---
enum ServiceCalculationType { byIndex, perPerson, perRoom }

// Extension để dễ dàng render text lên UI và lấy value gửi cho Backend
extension ServiceCalculationTypeExt on ServiceCalculationType {
  String get backendValue {
    switch (this) {
      case ServiceCalculationType.byIndex: return 'BY_INDEX';
      case ServiceCalculationType.perPerson: return 'PER_PERSON';
      case ServiceCalculationType.perRoom: return 'PER_ROOM';
    }
  }

  String get label {
    switch (this) {
      case ServiceCalculationType.byIndex: return 'Theo chỉ số';
      case ServiceCalculationType.perPerson: return 'Theo người';
      case ServiceCalculationType.perRoom: return 'Theo phòng';
    }
  }

  // Hàm sinh đơn vị động dựa theo tên dịch vụ
  String getUnit(String serviceName) {
    if (this == ServiceCalculationType.byIndex) {
      if (serviceName.toLowerCase() == 'điện') return 'VNĐ/kWh';
      if (serviceName.toLowerCase() == 'nước') return 'VNĐ/khối';
      return 'VNĐ/đơn vị';
    } else if (this == ServiceCalculationType.perPerson) {
      return 'VNĐ/người';
    } else {
      return 'VNĐ/phòng';
    }
  }
}

// Lớp đại diện cho 1 Dịch vụ trên màn hình
class AppServiceItem {
  String name;
  ServiceCalculationType calcType;
  TextEditingController priceController;

  AppServiceItem({
    required this.name,
    required this.calcType,
  }) : priceController = TextEditingController();
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // --- 1. THÔNG TIN KHU TRỌ ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  int _invoiceDay = 1;
  int _dueDate = 5;

  // --- 2. THÔNG TIN PHÒNG HÀNG LOẠT (MẶC ĐỊNH) ---
  final TextEditingController _areaSizeController = TextEditingController();
  final TextEditingController _rentPriceController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();
  final TextEditingController _maxOccupantsController = TextEditingController();

  // --- 3. DỊCH VỤ CƠ BẢN (Quản lý bằng List thay vì biến lẻ) ---
  final List<AppServiceItem> _services = [
    AppServiceItem(name: 'Điện', calcType: ServiceCalculationType.byIndex),
    AppServiceItem(name: 'Nước', calcType: ServiceCalculationType.byIndex),
    AppServiceItem(name: 'Rác', calcType: ServiceCalculationType.perPerson),
    AppServiceItem(name: 'Wifi', calcType: ServiceCalculationType.perRoom),
  ];

  // --- 4. CẤU HÌNH TẦNG ĐỘNG ---
  final TextEditingController _floorCountController = TextEditingController();
  int _floorCount = 0;
  final List<TextEditingController> _roomsPerFloorControllers = [];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _areaSizeController.dispose();
    _rentPriceController.dispose();
    _depositController.dispose();
    _maxOccupantsController.dispose();
    _floorCountController.dispose();

    // Dispose tất cả controller của phòng và dịch vụ
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

  void _submitData() {
    List<int> roomsPerFloor = _roomsPerFloorControllers
        .map((controller) => int.tryParse(controller.text) ?? 0)
        .toList();

    // Map dữ liệu dịch vụ sang List format của BE
    List<Map<String, dynamic>> servicesPayload = _services.map((s) {
      return {
        'name': s.name,
        'calcType': s.calcType.backendValue, // Trả ra đúng 'BY_INDEX', 'PER_PERSON'...
        'price': s.priceController.text.isEmpty ? 0 : num.tryParse(s.priceController.text) ?? 0,
      };
    }).toList();

    print('--- Dữ liệu gửi đi (OnboardingRequest) ---');
    print('Name: ${_nameController.text}');
    print('Address: ${_addressController.text}');
    print('Rooms Per Floor: $roomsPerFloor');
    print('Services: $servicesPayload');
    print('-------------------------------------------');

    // TODO: Gọi API POST
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
            _buildGeneralInfoCard(),

            const SizedBox(height: 20),
            _buildSectionTitle('2. Cấu hình dịch vụ cơ bản'),
            _buildServicesCard(),

            const SizedBox(height: 20),
            _buildSectionTitle('3. Cấu hình phòng mẫu'),
            _buildDefaultRoomCard(),

            const SizedBox(height: 20),
            _buildSectionTitle('4. Cấu hình số lượng phòng'),
            _buildDynamicFloorCard(),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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

  Widget _buildGeneralInfoCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên khu trọ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _invoiceDay,
                    decoration: const InputDecoration(labelText: 'Ngày chốt HĐ', border: OutlineInputBorder()),
                    items: List.generate(31, (index) => DropdownMenuItem(value: index + 1, child: Text('${index + 1}'))),
                    onChanged: (value) => setState(() => _invoiceDay = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _dueDate,
                    decoration: const InputDecoration(labelText: 'Hạn chót đóng', border: OutlineInputBorder()),
                    items: List.generate(31, (index) => DropdownMenuItem(value: index + 1, child: Text('${index + 1}'))),
                    onChanged: (value) => setState(() => _dueDate = value!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- CẬP NHẬT GIAO DIỆN PHẦN CẤU HÌNH DỊCH VỤ ---
  Widget _buildServicesCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        // Dùng danh sách để build UI linh hoạt
        child: Column(
          children: List.generate(_services.length, (index) {
            final service = _services[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dropdown Chọn loại tính toán
                      Expanded(
                        flex: 5,
                        child: DropdownButtonFormField<ServiceCalculationType>(
                          isExpanded: true,
                          value: service.calcType,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(),
                          ),
                          items: ServiceCalculationType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.label,overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              service.calcType = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Textfield Nhập giá tiền và hiển thị đơn vị tương ứng
                      Expanded(
                        flex: 6,
                        child: TextField(
                          controller: service.priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Đơn giá',
                            suffixText: service.calcType.getUnit(service.name),
                            suffixStyle: const TextStyle(fontSize: 12, color: Colors.black54),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDefaultRoomCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: TextField(controller: _rentPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Giá thuê (VNĐ)', border: OutlineInputBorder()))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _depositController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tiền cọc (VNĐ)', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _areaSizeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Diện tích (m2)', border: OutlineInputBorder()))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _maxOccupantsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số người tối đa', border: OutlineInputBorder()))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicFloorCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _floorCountController,
              keyboardType: TextInputType.number,
              onChanged: _updateFloorCount,
              decoration: const InputDecoration(
                labelText: 'Số tầng',
                hintText: 'Nhập số tầng của khu trọ (VD: 3)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_floorCount > 0) ...[
              const SizedBox(height: 16),
              const Text('Điều chỉnh số phòng cho từng tầng:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _floorCount,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Text('Tầng ${index + 1}:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _roomsPerFloorControllers[index],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(),
                              suffixText: 'phòng',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ]
          ],
        ),
      ),
    );
  }
}