import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../../../data/providers/user_provider.dart';

class SignatureViewModel extends ChangeNotifier {
  final UserProvider _userProvider = UserProvider();

  final SignatureController signatureController = SignatureController(
    penStrokeWidth: 4,
    penColor: const Color(0xFF0D47A1),
    exportBackgroundColor: Colors.white,
  );

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<String?> uploadSignature() async {
    // 1. Kiểm tra xem người dùng đã vẽ gì chưa
    if (signatureController.isEmpty) {
      _errorMessage = 'Vui lòng vẽ chữ ký của bạn trước khi lưu!';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 2. Xuất dữ liệu bảng vẽ thành mảng Bytes PNG
      final Uint8List? imageBytes = await signatureController.toPngBytes();
      if (imageBytes == null) {
        throw Exception('Không thể xuất dữ liệu chữ ký!');
      }

      // 3. Gọi API upload
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

  void clearSignature() {
    signatureController.clear();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    signatureController.dispose();
    super.dispose();
  }
}