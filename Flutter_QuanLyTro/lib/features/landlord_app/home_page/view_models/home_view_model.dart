import 'package:flutter/material.dart';
import '../../../../data/repository/issue_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final IssueRepository _issueRepository = IssueRepository();

  int _pendingIssuesCount = 0;
  int get pendingIssuesCount => _pendingIssuesCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchPendingIssuesCount(String? areaId) async {
    _isLoading = true;

    try {

      final response = await _issueRepository.getIssuesForLandlord(
        page: 0,
        size: 1,
        status: 'PENDING',
        areaId: areaId,
      );


      final int total = response['totalElements'] ?? 0;

      if (_pendingIssuesCount != total) {
        _pendingIssuesCount = total;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi tải số lượng sự cố PENDING: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}