import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/request/user_update_request.dart';
import '../../../../data/models/response/user_model.dart';
import 'view_models/tenant_list_view_model.dart';

class TenantListScreen extends StatelessWidget {
  const TenantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TenantListViewModel>();

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (viewModel.errorMessage != null && viewModel.tenants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(viewModel.errorMessage!),
            TextButton(
              onPressed: viewModel.fetchTenants,
              child: const Text('Thử lại'),
            )
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quản lý Khách thuê',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cập nhật thông tin và mật khẩu khách thuê',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // --- DANH SÁCH KHÁCH THUÊ ---
            Expanded(
              child: viewModel.tenants.isEmpty
                  ? const Center(child: Text('Chưa có khách thuê nào trong khu trọ này.'))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: viewModel.tenants.length,
                itemBuilder: (context, index) {
                  final tenant = viewModel.tenants[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.person, color: AppColors.primary),
                      ),
                      title: Text(tenant.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('SĐT: ${tenant.phone}'),
                          // Hiển thị CCCD nếu có
                          if (tenant.idCardNumber != null && tenant.idCardNumber!.isNotEmpty)
                            Text('CCCD: ${tenant.idCardNumber}'),
                          if (tenant.hometown != null && tenant.hometown!.isNotEmpty)
                            Text('Quê quán: ${tenant.hometown}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_note, color: Colors.orange, size: 28),
                        onPressed: () => _showEditDialog(context, tenant, viewModel),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, UserModel tenant, TenantListViewModel viewModel) {
    final nameCtrl = TextEditingController(text: tenant.fullName);
    final phoneCtrl = TextEditingController(text: tenant.phone);
    final idCardCtrl = TextEditingController(text: tenant.idCardNumber);
    final dobCtrl = TextEditingController(text: tenant.dob);
    final hometownCtrl = TextEditingController(text: tenant.hometown);
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cập nhật thông tin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Họ và tên')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Số điện thoại')),
              TextField(controller: dobCtrl, decoration: const InputDecoration(labelText: 'Ngày sinh (yyyy-MM-dd)')),
              TextField(controller: hometownCtrl, decoration: const InputDecoration(labelText: 'Quê quán')),
              const Divider(height: 30),
              const Text('Đổi mật khẩu (Bỏ trống nếu không đổi)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              TextField(
                controller: passwordCtrl,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final request = UserUpdateRequest(
                fullName: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                dob: dobCtrl.text.trim().isEmpty ? null : dobCtrl.text.trim(),
                hometown: hometownCtrl.text.trim(),
                password: passwordCtrl.text.trim().isEmpty ? null : passwordCtrl.text.trim(),
              );

              final success = await viewModel.updateTenant(tenant.id, request);

              if (!context.mounted) return;

              if (success) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: Colors.green));
              } else if (viewModel.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.errorMessage!), backgroundColor: Colors.red));
                viewModel.clearError();
              }
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}