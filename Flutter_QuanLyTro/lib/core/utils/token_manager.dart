import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  // Khởi tạo đối tượng storage
  static const _storage = FlutterSecureStorage();

  // Định nghĩa các khóa (keys) để tránh gõ sai chính tả
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyRole = 'role';

  // --- 1. LƯU DỮ LIỆU ---
  // Dùng { } để biến các tham số thành Optional Named Parameters,
  // vì có thể lúc đăng nhập bạn chỉ có accessToken, chưa có refreshToken.
  static Future<void> saveAuthData({
    required String accessToken,
    String? refreshToken,
    String? userId,
    String? role,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);

    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
    if (userId != null) {
      await _storage.write(key: _keyUserId, value: userId);
    }
    if (role != null) {
      await _storage.write(key: _keyRole, value: role);
    }
  }

  // --- 2. LẤY DỮ LIỆU ---
  // Lưu ý: Các hàm này giờ trả về Future<String?> nên khi gọi phải dùng từ khóa 'await'
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: _keyRole);
  }

  // --- 3. XÓA DỮ LIỆU KHI ĐĂNG XUẤT ---
  static Future<void> clearAuthData() async {
    // Xóa toàn bộ dữ liệu đã lưu trong secure storage
    await _storage.deleteAll();
  }
}