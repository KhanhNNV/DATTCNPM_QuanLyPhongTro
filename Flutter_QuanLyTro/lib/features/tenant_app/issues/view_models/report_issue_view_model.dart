import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/repository/issue_repository.dart';

class ReportIssueViewModel extends ChangeNotifier {
  final IssueRepository _repository = IssueRepository();

  final String roomId;

  ReportIssueViewModel({required this.roomId});

  final TextEditingController descriptionController = TextEditingController();

  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Chọn ảnh từ Thư viện hoặc Camera
  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (pickedFile != null) {
      _selectedImage = File(pickedFile.path);
      notifyListeners();
    }
  }

  void removeImage() {
    _selectedImage = null;
    notifyListeners();
  }


  Future<bool> submitIssue() async {
    final description = descriptionController.text.trim();
    if (description.isEmpty) {
      _errorMessage = 'Vui lòng nhập mô tả sự cố!';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.reportIssue(
        roomId: roomId,
        description: description,
        image: _selectedImage,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }
}