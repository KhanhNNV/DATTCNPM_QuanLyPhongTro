import 'dart:convert';

class ApiErrorHandler {
  /// Hàm trích xuất thông báo lỗi từ Exception (hoặc response body)
  static String extractErrorMessage(Object error) {
    // Nếu lỗi truyền vào là dạng Exception: {...}, ta cắt bỏ chữ "Exception: "
    String rawData = error.toString().replaceFirst('Exception: ', '').trim();

    try {
      // Cố gắng parse chuỗi lỗi sang JSON
      final Map<String, dynamic> decoded = jsonDecode(rawData);

      // Lấy thông báo chính (message)
      String finalMessage = decoded['message'] ?? 'Đã xảy ra lỗi không xác định';

      // Xử lý phần chi tiết (details) nếu có
      if (decoded['details'] != null) {
        final details = decoded['details'];

        if (details is String && details.isNotEmpty) {
          // Trường hợp details là chuỗi (VD: lỗi thiếu param, JSON sai format)
          finalMessage += '\nChi tiết: $details';
        } else if (details is Map && details.isNotEmpty) {
          // Trường hợp details là Map (VD: lỗi @Valid thiếu tên, sđt)
          List<String> fieldErrors = [];
          details.forEach((key, value) {
            fieldErrors.add('• $value');
          });
          finalMessage += '\n' + fieldErrors.join('\n');
        }
      }

      return finalMessage;
    } catch (e) {
      // Nếu không thể parse JSON (do lỗi kết nối mạng, 404 không có body,...),
      // thì trả về lỗi gốc hoặc một thông báo chung.
      return rawData.isNotEmpty ? rawData : 'Lỗi kết nối đến máy chủ';
    }
  }
}