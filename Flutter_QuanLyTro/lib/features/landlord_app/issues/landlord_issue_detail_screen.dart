import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import 'view_models/landlord_issue_detail_view_model.dart';

class LandlordIssueDetailScreen extends StatelessWidget {
  const LandlordIssueDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LandlordIssueDetailViewModel>();
    final issue = vm.currentIssue;

    final statusColor = _getStatusColor(issue.status);
    final statusText = _getStatusText(issue.status);

    return WillPopScope(
      onWillPop: () async {
        // Trả về hasChanged để màn list biết có cần gọi lại API list hay không
        Navigator.pop(context, vm.hasChanged);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: CustomAppBar(
          title: 'Chi tiết sự cố',
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hình ảnh sự cố
              if (issue.imageUrl != null && issue.imageUrl!.isNotEmpty)
                Image.network(
                  issue.imageUrl!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                    );
                  },
                ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Trạng thái
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Thông tin cơ bản
                    _buildInfoCard(issue),
                    const SizedBox(height: 16),

                    // 4. Nội dung mô tả
                    const Text(
                      'Mô tả chi tiết',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        issue.description,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),

                    // 5. Ghi chú giải quyết (Tự động hiện sau khi update API thành công)
                    if (issue.solutionNote != null && issue.solutionNote!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Ghi chú xử lý',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          issue.solutionNote!,
                          style: TextStyle(fontSize: 15, height: 1.5, color: Colors.green[900]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // --- NÚT ĐIỀU HƯỚNG BÊN DƯỚI DÀNH CHO CHỦ TRỌ ---
        bottomNavigationBar: _buildBottomActions(context, vm),
      ),
    );
  }

  Widget _buildInfoCard(issue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.meeting_room_outlined, 'Phòng', issue.roomNumber),
          const Divider(height: 24),
          _buildInfoRow(Icons.person_outline, 'Người báo', issue.tenantName),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.access_time,
            'Ngày gửi',
            issue.createdAt != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(issue.createdAt!)
                : '---',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  /// Nút hành động cập nhật trạng thái nằm ở đáy màn hình
  Widget? _buildBottomActions(BuildContext context, LandlordIssueDetailViewModel vm) {
    if (vm.currentIssue.status == 'COMPLETED') {
      return null; // Đã xong thì không hiện nút nữa
    }

    String buttonText = vm.currentIssue.status == 'PENDING' ? 'Tiếp nhận xử lý' : 'Đánh dấu hoàn thành';
    String targetStatus = vm.currentIssue.status == 'PENDING' ? 'ACCEPTED' : 'COMPLETED';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: vm.isLoading ? null : () => _showUpdateDialog(context, vm, targetStatus, buttonText),
          child: vm.isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
            buttonText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  /// Dialog nhập ghi chú giải quyết
  void _showUpdateDialog(BuildContext context, LandlordIssueDetailViewModel vm, String targetStatus, String actionName) {
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(actionName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nhập ghi chú xử lý (sẽ gửi cho khách thuê - không bắt buộc):'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'VD: Đã gọi thợ điện, chiều nay sẽ qua sửa...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(ctx); // Đóng dialog
              FocusScope.of(context).unfocus(); // Hạ bàn phím

              final note = noteController.text.trim();
              final success = await vm.updateStatus(targetStatus, note);

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cập nhật trạng thái thành công!'), backgroundColor: Colors.green),
                );
              } else if (vm.errorMessage != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(vm.errorMessage!), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'ACCEPTED': return Colors.blue;
      case 'COMPLETED': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING': return 'Chờ xử lý';
      case 'ACCEPTED': return 'Đang xử lý';
      case 'COMPLETED': return 'Đã hoàn thành';
      default: return status;
    }
  }
}