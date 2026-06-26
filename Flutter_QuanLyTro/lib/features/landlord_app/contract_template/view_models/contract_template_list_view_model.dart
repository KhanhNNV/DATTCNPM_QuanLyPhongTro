import 'package:flutter/material.dart';
import '../../../../data/models/response/contract_template_response.dart';
import '../../../../data/repository/contract_template_repository.dart';

class ContractTemplateListViewModel extends ChangeNotifier {
  final ContractTemplateRepository _repository = ContractTemplateRepository();

  final searchController = TextEditingController();

  bool isLoading = false;
  bool isUpdatingActive = false;
  String? errorMessage;

  List<ContractTemplateResponse> _allTemplates = [];
  List<ContractTemplateResponse> displayedTemplates = [];
  String? selectedTemplateId;


  ContractTemplateListViewModel() {
    searchController.addListener(() {
      _applyLocalSearch(searchController.text);
    });
  }

  Future<void> fetchTemplates() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      _allTemplates = await _repository.getAllTemplates();

      try {
        selectedTemplateId = _allTemplates.firstWhere((t) => t.isActive == true).id;
      } catch (e) {
        selectedTemplateId = _allTemplates.isNotEmpty ? _allTemplates.first.id : null;
      }

      _applyLocalSearch(searchController.text);
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectTemplate(String id) async {
    if (selectedTemplateId == id || isUpdatingActive) return;

    final String? previousId = selectedTemplateId;
    selectedTemplateId = id;
    isUpdatingActive = true;
    notifyListeners();

    try {
      await _repository.setActiveTemplate(id);
    } catch (e) {
      selectedTemplateId = previousId;
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      isUpdatingActive = false;
      notifyListeners();
    }
  }

  void _applyLocalSearch(String query) {
    if (query.trim().isEmpty) {
      displayedTemplates = List.from(_allTemplates);
    } else {
      final cleanQuery = query.trim().toLowerCase();
      displayedTemplates = _allTemplates.where((template) {
        return template.name.toLowerCase().contains(cleanQuery);
      }).toList();
    }
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}