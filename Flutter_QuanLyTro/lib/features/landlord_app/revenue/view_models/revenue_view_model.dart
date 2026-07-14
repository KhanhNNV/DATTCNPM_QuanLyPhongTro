import 'package:flutter/material.dart';
import '../../../../data/models/response/revenue_report_response.dart';
import '../../../../data/repository/revenue_repository.dart';

class RevenueViewModel extends ChangeNotifier {
  final RevenueRepository _repository = RevenueRepository();
  final String areaId;

  RevenueViewModel({required this.areaId}) {
    _selectedDate = DateTime.now();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  RevenueReportResponse? _report;
  RevenueReportResponse? get report => _report;

  late DateTime _selectedDate;
  DateTime get selectedDate => _selectedDate;

  /// Gọi API lấy dữ liệu báo cáo
  Future<void> fetchRevenueReport() async {
    _isLoading = true;
    _errorMessage = null;
    _report = null;
    notifyListeners();

    try {
      // Định dạng ngày về dạng YYYY-MM-01 để khớp ISO.DATE của Spring Boot
      final String formattedMonth =
          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-01";

      _report = await _repository.getRevenueReport(
        month: formattedMonth,
        areaId: areaId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thay đổi tháng lọc và tự động tải lại dữ liệu
  void changeMonth(DateTime newDate) {
    _selectedDate = newDate;
    fetchRevenueReport();
  }
}