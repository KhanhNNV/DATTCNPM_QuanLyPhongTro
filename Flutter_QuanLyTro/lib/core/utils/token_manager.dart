class TokenManager {
  static String? _accessToken;

  // Lưu token vào bộ nhớ
  static void saveToken(String token) {
    _accessToken = token;
  }

  // Lấy token ra để kẹp vào API
  static String? getToken() {
    return _accessToken;
  }

  // Xóa token khi đăng xuất
  static void clearToken() {
    _accessToken = null;
  }
}