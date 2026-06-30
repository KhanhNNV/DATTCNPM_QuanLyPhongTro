import 'package:intl/intl.dart';

class TemplateCompiler {
  /// Hàm thay thế các từ khóa {{...}} thành dữ liệu thật
  static String compileText(String rawText, Map<String, dynamic> data) {
    if (rawText.isEmpty) return rawText;

    String result = rawText;
    data.forEach((key, value) {
      // Tìm và thay thế tất cả các chuỗi {{KEY}} bằng value
      result = result.replaceAll('{{$key}}', value.toString());
    });

    // Nếu sau khi map xong vẫn còn dư những biến {{...}} chưa có data,
    // bạn có thể thay nó thành "..." để không bị in mã code ra hợp đồng.
    result = result.replaceAll(RegExp(r'\{\{.*?\}\}'), '.......');

    return result;
  }

  /// Helper format tiền tệ VNĐ (ví dụ: 3000000 -> 3,000,000)
  static String formatCurrency(double amount) {
    final format = NumberFormat.decimalPattern('en_US');
    return format.format(amount);
  }
}