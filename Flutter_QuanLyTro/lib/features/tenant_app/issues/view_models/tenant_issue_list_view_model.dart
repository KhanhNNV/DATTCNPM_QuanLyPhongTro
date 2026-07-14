import 'package:flutter/material.dart';
import '../../../../data/models/response/issue_response.dart';
import '../../../../data/repository/issue_repository.dart';

class TenantIssueListViewModel extends ChangeNotifier {
  final IssueRepository _repository = IssueRepository();


  List<IssueResponse> _issues = [];
  List<IssueResponse> get issues => _issues;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isFetchingMore = false;
  bool get isFetchingMore => _isFetchingMore;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _selectedStatus;
  String? get selectedStatus => _selectedStatus;


  int _currentPage = 0;
  final int _pageSize = 10;
  bool _isLastPage = false;


  final Map<String?, String> statusMap = {
    null: 'Tất cả',
    'PENDING': 'Chờ xử lý',
    'ACCEPTED': 'Đang xử lý',
    'COMPLETED': 'Đã hoàn thành',
  };

  Future<void> fetchIssues({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 0;
      _isLastPage = false;
      _errorMessage = null;
      _isLoading = true;
      _issues = [];
      notifyListeners();
    } else {

      if (_isLastPage || _isFetchingMore) return;
      _isFetchingMore = true;
      notifyListeners();
    }

    try {
      final responseData = await _repository.getMyIssues(
        page: _currentPage,
        size: _pageSize,
        status: _selectedStatus,
      );

      final List<dynamic> content = responseData['content'] ?? [];
      final List<IssueResponse> fetchedItems = content.map((json) => IssueResponse.fromJson(json)).toList();

      _isLastPage = responseData['last'] ?? true;

      if (isRefresh) {
        _issues = fetchedItems;
      } else {
        _issues.addAll(fetchedItems);
      }

      if (!_isLastPage) {
        _currentPage++;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  void changeStatus(String? status) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
      fetchIssues(isRefresh: true);
    }
  }
}