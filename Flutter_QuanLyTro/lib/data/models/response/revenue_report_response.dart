class RevenueReportResponse {
  final DateTime? period;
  final int totalInvoices;
  final int paidInvoicesCount;
  final int pendingInvoicesCount;
  final int unpaidInvoicesCount;
  final double totalCollectedAmount;
  final double totalPendingAmount;
  final double totalDebtAmount;

  RevenueReportResponse({
    this.period,
    required this.totalInvoices,
    required this.paidInvoicesCount,
    required this.pendingInvoicesCount,
    required this.unpaidInvoicesCount,
    required this.totalCollectedAmount,
    required this.totalPendingAmount,
    required this.totalDebtAmount,
  });

  factory RevenueReportResponse.fromJson(Map<String, dynamic> json) {
    return RevenueReportResponse(
      period: json['period'] != null ? DateTime.parse(json['period']) : null,
      totalInvoices: json['totalInvoices'] ?? 0,
      paidInvoicesCount: json['paidInvoicesCount'] ?? 0,
      pendingInvoicesCount: json['pendingInvoicesCount'] ?? 0,
      unpaidInvoicesCount: json['unpaidInvoicesCount'] ?? 0,
      totalCollectedAmount: (json['totalCollectedAmount'] ?? 0).toDouble(),
      totalPendingAmount: (json['totalPendingAmount'] ?? 0).toDouble(),
      totalDebtAmount: (json['totalDebtAmount'] ?? 0).toDouble(),
    );
  }
}