import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../data/providers/user_provider.dart';

class SignatureViewModel extends ChangeNotifier {
  final UserProvider _userProvider = UserProvider();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<String?> uploadSignature(Uint8List imageBytes) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final signatureUrl = await _userProvider.updateSignature(imageBytes);
      return signatureUrl;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}