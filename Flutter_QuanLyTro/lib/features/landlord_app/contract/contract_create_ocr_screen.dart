import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/features/landlord_app/contract/view_models/contract_create_view_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/models/response/contract_create_response.dart';



class ContractCreateOcrScreen extends StatelessWidget {
  const ContractCreateOcrScreen({Key? key}) : super(key: key);

  void _onSubmit(BuildContext context, ContractCreateViewModel vm) async {
    FocusScope.of(context).unfocus(); // Ẩn bàn phím
    try {
      final response = await vm.submitContract();
      if (response != null && context.mounted) {
        _showSuccessDialog(context, response);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessDialog(BuildContext context, ContractCreateResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Thành công', style: TextStyle(color: Colors.green)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(response.message),
            const SizedBox(height: 12),
            const Text('Tài khoản khách thuê:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Tài khoản: ${response.tenantUsername}'),
            Text('Mật khẩu: ${response.tenantRawPassword}', style: const TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Đóng Dialog
              Navigator.pop(context); // Quay về Home
            },
            child: const Text('Hoàn tất'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, ContractCreateViewModel vm, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      if (isStart) {
        vm.changeStartDate(picked);
      } else {
        vm.changeEndDate(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe ViewModel từ Router truyền xuống
    final viewModel = context.watch<ContractCreateViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lập hợp đồng mới'),
        elevation: 0,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: viewModel.formKey, // Lấy từ ViewModel
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1. Thông tin cơ bản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: viewModel.roomIdController,
                decoration: const InputDecoration(labelText: 'ID Phòng (VD: uuid)', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: viewModel.templateIdController,
                decoration: const InputDecoration(labelText: 'ID Mẫu Hợp Đồng', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: viewModel.phoneController,
                decoration: const InputDecoration(labelText: 'SĐT Khách Thuê', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: viewModel.depositAmountController,
                decoration: const InputDecoration(labelText: 'Tiền cọc (VNĐ)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 12),

              // Chọn ngày
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, viewModel, true),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(viewModel.startDate == null
                          ? 'Ngày bắt đầu'
                          : DateFormat('dd/MM/yyyy').format(viewModel.startDate!)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, viewModel, false),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(viewModel.endDate == null
                          ? 'Ngày kết thúc'
                          : DateFormat('dd/MM/yyyy').format(viewModel.endDate!)),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              const Text('2. Quét CCCD Khách thuê (Bắt buộc)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildImagePickerBox(
                    context: context,
                    title: 'Mặt trước',
                    imageFile: viewModel.frontImage,
                    isFront: true,
                    viewModel: viewModel,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildImagePickerBox(
                    context: context,
                    title: 'Mặt sau',
                    imageFile: viewModel.backImage,
                    isFront: false,
                    viewModel: viewModel,
                  )),
                ],
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _onSubmit(context, viewModel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('TẠO HỢP ĐỒNG & QUÉT OCR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerBox({
    required BuildContext context,
    required String title,
    required File? imageFile,
    required bool isFront,
    required ContractCreateViewModel viewModel,
  }) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('Chụp ảnh'),
                      onTap: () {
                        Navigator.pop(ctx);
                        viewModel.pickImage(isFront: isFront, fromCamera: true);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_library),
                      title: const Text('Chọn từ thư viện'),
                      onTap: () {
                        Navigator.pop(ctx);
                        viewModel.pickImage(isFront: isFront, fromCamera: false);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid),
            ),
            child: imageFile != null
                ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(imageFile, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () => viewModel.removeImage(isFront: isFront),
                    child: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                )
              ],
            )
                : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: Colors.grey, size: 32),
                  SizedBox(height: 4),
                  Text('Tải ảnh lên', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}