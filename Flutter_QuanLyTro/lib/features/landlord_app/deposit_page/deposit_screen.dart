import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/landlord_app/deposit_page/view_models/deposit_view_model.dart';

import '../../../../data/models/request/deposit_create_request.dart';
import '../../../data/models/response/room_model.dart';


class DepositScreen extends StatefulWidget {
  final String areaId;

  const DepositScreen({
    super.key,
    required this.areaId,
  });

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final DepositViewModel vm = DepositViewModel();

  final _formKey = GlobalKey<FormState>();

  final _tenantController = TextEditingController();
  final _phoneController = TextEditingController();
  final _depositController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _expectedMoveInDate;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    await vm.loadRooms(widget.areaId);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _expectedMoveInDate = date;
      });
    }
  }

  Future<void> _saveDeposit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (vm.selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn phòng'),
        ),
      );
      return;
    }

    if (_expectedMoveInDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày dự kiến vào ở'),
        ),
      );
      return;
    }

    try {
      final request = DepositCreateRequest(
        roomId: vm.selectedRoom!.id,
        phone: _phoneController.text.trim(),
        tenantFullName: _tenantController.text.trim(),
        depositAmount: double.parse(
          _depositController.text.trim(),
        ),
        expectedMoveInDate:
        _expectedMoveInDate!
            .toIso8601String()
            .split('T')
            .first,
        note: _noteController.text.trim(),
      );

      await vm.createDeposit(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo phiếu đặt cọc thành công'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  Widget _buildRoomCard(RoomModel room) {
    final isSelected =
        vm.selectedRoom?.id == room.id;

    return Card(
      color:
      isSelected
          ? Colors.blue.shade50
          : Colors.white,
      child: RadioListTile<String>(
        value: room.id,
        groupValue: vm.selectedRoom?.id,
        onChanged: (_) {
          vm.selectRoom(room);

          _depositController.text =
              room.depositAmount.toStringAsFixed(0);

          setState(() {});
        },
        title: Text(
          'Phòng ${room.roomNumber}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text('Tầng: ${room.floor}'),
            Text(
              'Diện tích: ${room.areaSize} m²',
            ),
            Text(
              'Giá thuê: ${room.rentPrice.toStringAsFixed(0)} đ',
            ),
            Text(
              'Tiền cọc: ${room.depositAmount.toStringAsFixed(0)} đ',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tenantController.dispose();
    _phoneController.dispose();
    _depositController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cọc giữ chỗ'),
      ),
      body:
      vm.isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : Form(
        key: _formKey,
        child: ListView(
          padding:
          const EdgeInsets.all(16),
          children: [
            const Text(
              'Chọn phòng',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ...vm.rooms.map(
                  (room) =>
                  _buildRoomCard(room),
            ),

            const SizedBox(height: 24),

            TextFormField(
              controller:
              _tenantController,
              decoration:
              const InputDecoration(
                labelText:
                'Tên khách thuê',
                border:
                OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Vui lòng nhập tên';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
              _phoneController,
              keyboardType:
              TextInputType.phone,
              decoration:
              const InputDecoration(
                labelText:
                'Số điện thoại',
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
              _depositController,
              keyboardType:
              TextInputType.number,
              decoration:
              const InputDecoration(
                labelText:
                'Tiền cọc',
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration:
                const InputDecoration(
                  labelText:
                  'Ngày dự kiến vào ở',
                  border:
                  OutlineInputBorder(),
                ),
                child: Text(
                  _expectedMoveInDate ==
                      null
                      ? 'Chọn ngày'
                      : '${_expectedMoveInDate!.day}/${_expectedMoveInDate!.month}/${_expectedMoveInDate!.year}',
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
              _noteController,
              maxLines: 3,
              decoration:
              const InputDecoration(
                labelText:
                'Ghi chú',
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed:
                _saveDeposit,
                child: const Text(
                  'TẠO PHIẾU ĐẶT CỌC',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}