import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'view_models/revenue_view_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class RevenueReportScreen extends StatelessWidget {
  const RevenueReportScreen({super.key});

  String _formatCurrency(double amount) {
    return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RevenueViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Thống kê doanh thu'),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tháng báo cáo: ${viewModel.selectedDate.month}/${viewModel.selectedDate.year}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text("Chọn tháng"),
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: viewModel.selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDatePickerMode: DatePickerMode.year,
                    );
                    if (picked != null) {
                      viewModel.changeMonth(picked);
                    }
                  },
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _buildMainContent(context, viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, RevenueViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(viewModel.errorMessage!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final report = viewModel.report;
    if (report == null) {
      return const Center(child: Text("Không có dữ liệu hiển thị."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(report.totalInvoices),
          const SizedBox(height: 20),
          const Text(
            "Thống kê số tiền",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
          ),
          const SizedBox(height: 10),
          _buildAmountTile(
            title: "Tổng tiền đã thu",
            amount: report.totalCollectedAmount,
            count: report.paidInvoicesCount,
            color: Colors.green,
            icon: Icons.check_circle_outline,
          ),
          _buildAmountTile(
            title: "Tổng tiền chờ duyệt",
            amount: report.totalPendingAmount,
            count: report.pendingInvoicesCount,
            color: Colors.orange,
            icon: Icons.hourglass_empty,
          ),
          _buildAmountTile(
            title: "Tổng tiền còn nợ (Nợ xấu)",
            amount: report.totalDebtAmount,
            count: report.unpaidInvoicesCount,
            color: Colors.red,
            icon: Icons.error_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int totalInvoices) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tổng hóa đơn phát sinh", style: TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            "$totalInvoices hóa đơn",
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountTile({
    required String title,
    required double amount,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(amount),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$count HĐ",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}