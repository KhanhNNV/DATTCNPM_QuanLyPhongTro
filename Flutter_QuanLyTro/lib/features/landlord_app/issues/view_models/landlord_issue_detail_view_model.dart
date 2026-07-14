import 'package:flutter/material.dart';
import '../../../../data/models/response/issue_response.dart';
import '../../../../data/repository/issue_repository.dart';

class LandlordIssueDetailViewModel extends ChangeNotifier {
  final IssueRepository _repository = IssueRepository();

  IssueResponse currentIssue;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool hasChanged = false;

  LandlordIssueDetailViewModel({required this.currentIssue});

  Future<bool> updateStatus(String newStatus, String? note) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedIssue = await _repository.updateIssueStatus(
        issueId: currentIssue.id,
        status: newStatus,
        solutionNote: note,
      );


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