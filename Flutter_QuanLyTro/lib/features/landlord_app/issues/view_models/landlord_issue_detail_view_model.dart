import 'package:flutter/material.dart';
import '../../../../data/models/response/issue_response.dart';
import '../../../../data/repository/issue_repository.dart';

class LandlordIssueDetailViewModel extends ChangeNotifier {
  final IssueRepository _repository = IssueRepository();

  // Biến lưu trữ sự cố hiện tại
  IssueResponse currentIssue;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Biến cờ để báo cho màn List biết có cần refresh không khi back lại
  bool hasChanged = false;

  LandlordIssueDetailViewModel({required this.currentIssue});

  Future<bool> updateStatus(String newStatus, String? note) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Gọi API cập nhật
      final updatedIssue = await _repository.updateIssueStatus(
        issueId: currentIssue.id,
        status: newStatus,
        solutionNote: note,
      );

      // Cập nhật lại đối tượng currentIssue, UI sẽ tự động build lại theo data này
      currentIssue = updatedIssue;
      hasChanged = true;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}