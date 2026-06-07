import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/area_model.dart';
import '../onboarding/widgets/general_info_card.dart';
import 'view_models/edit_area_view_model.dart';

class EditAreaScreen extends StatefulWidget {
  final AreaModel area;

  const EditAreaScreen({
    super.key,
    required this.area,
  });

  @override
  State<EditAreaScreen> createState() => _EditAreaScreenState();
}

class _EditAreaScreenState extends State<EditAreaScreen> {
  final EditAreaViewModel _viewModel = EditAreaViewModel();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  int _invoiceDay = 1;
  int _dueDate = 5;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _viewModel.addListener(_onViewModelChanged);
  }

  void _loadInitialData() {
    _nameController.text = widget.area.name;
    _addressController.text = widget.area.address;
    _invoiceDay = widget.area.invoiceDay;
    _dueDate = widget.area.dueDate;
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
    _viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    final payload = {
      "name": _nameController.text.trim(),
      "address": _addressController.text.trim(),
      "invoiceDay": _invoiceDay,
      "dueDate": _dueDate,
    };

    final success = await _viewModel.updateAreaInfo(
      areaId: widget.area.id,
      payload: payload,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cập nhật thông tin khu trọ thành công"),
          backgroundColor: Colors.green,
        ),
      );
      // Trả về true để màn hình trước biết là đã update thành công và reload data
      Navigator.pop(context, true);
    }
  }

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0, left: 4.0),
              child: Text(
                'Thông tin cơ bản',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            GeneralInfoCard(
              nameController: _nameController,
              addressController: _addressController,
              invoiceDay: _invoiceDay,
              dueDate: _dueDate,
              onInvoiceDayChanged: (val) => setState(() => _invoiceDay = val!),
              onDueDateChanged: (val) => setState(() => _dueDate = val!),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _viewModel.isLoading ? null : _submitUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _viewModel.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                'Lưu thay đổi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}