import 'package:flutter/material.dart';
import '../../../../data/repository/issue_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final IssueRepository _issueRepository = IssueRepository();

  // Biến lưu trữ số lượng sự cố đang chờ xử lý
  int _pendingIssuesCount = 0;
  int get pendingIssuesCount => _pendingIssuesCount;

  // Trạng thái đang tải (nếu cần dùng hiển thị loading)
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Gọi API để lấy tổng số lượng sự cố có trạng thái 'PENDING'
  Future<void> fetchPendingIssuesCount(String? areaId) async {
    _isLoading = true;

    try {
      // Chỉ lấy trang 0, size 1 để giảm tải dữ liệu, ta chỉ cần 'totalElements'
      final response = await _issueRepository.getIssuesForLandlord(
        page: 0,
        size: 1,
        status: 'PENDING',
        areaId: areaId,
      );

      // Trích xuất tổng số lượng phần tử
      final int total = response['totalElements'] ?? 0;

      // Nếu số lượng thay đổi thì mới cập nhật và build lại UI
      if (_pendingIssuesCount != total) {
        _pendingIssuesCount = total;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi tải số lượng sự cố PENDING: $e');
    } finally {
      _isLoading = false;
      // Dù thành công hay lỗi vẫn notify để tắt trạng thái loading nếu có component nào đang dùng
      notifyListeners();
    }
  }
}