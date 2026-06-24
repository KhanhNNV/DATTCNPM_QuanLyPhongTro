import 'package:flutter/material.dart';
import '../../../../data/models/response/contract_template_response.dart';

class ContractTemplateListViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  // Lưu danh sách gốc từ API (Giả lập)
  List<ContractTemplateResponse> _allTemplates = [];

  // Danh sách thực tế sẽ hiển thị lên màn hình (sau khi tìm kiếm)
  List<ContractTemplateResponse> displayedTemplates = [];

  // Từ khóa tìm kiếm
  String searchQuery = '';

  // ID của mẫu hợp đồng đang được chọn (Radio)
  String? selectedTemplateId;

  // HÀM LẤY DỮ LIỆU (Đã bổ sung đầy đủ thuộc tính mới)
  Future<void> fetchTemplates() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      // Giả lập độ trễ mạng
      await Future.delayed(const Duration(milliseconds: 800));

      // Khởi tạo dữ liệu giả lập chuẩn theo Model mới của bạn
      _allTemplates = [
        ContractTemplateResponse(
          id: 'TPL_001',
          name: 'Mẫu hợp đồng chuẩn năm 2026',
          content: 'Điều 1: Giá thuê là {{GIA_THUE}} VND/tháng.\nĐiều 2: Tiền cọc là {{TIEN_COC}} VND.\nĐiều 3: Bên B cam kết giữ gìn vệ sinh chung...',
          isSystemTemplate: true, // Mẫu do hệ thống cung cấp mặc định
          createdAt: '2026-01-01T08:00:00Z',
          updatedAt: '2026-06-20T15:30:00Z',
        ),
        ContractTemplateResponse(
          id: 'TPL_002',
          name: 'Mẫu hợp đồng Sinh viên (Tối giản)',
          content: 'Hợp đồng dành riêng cho sinh viên.\nĐiều 1: Giờ giới nghiêm là 23h00.\nĐiều 2: Không tụ tập ăn nhậu ồn ào.\nBên thuê: {{TEN_KHACH}}',
          isSystemTemplate: true,
          createdAt: '2026-02-15T09:00:00Z',
          updatedAt: '2026-02-15T09:00:00Z',
        ),
        ContractTemplateResponse(
          id: 'TPL_003',
          name: 'Mẫu hợp đồng tự tạo viết tay',
          content: 'Điều khoản tự chọn: Bên B được phép nuôi thú cưng nhỏ nhưng phải cam kết không gây mùi hôi và tiếng ồn ảnh hưởng phòng khác.',
          isSystemTemplate: false, // Mẫu do chủ trọ tự tạo thêm
          createdAt: '2026-06-22T10:00:00Z',
          updatedAt: '2026-06-23T17:45:00Z',
        ),
      ];

      // Mặc định tự động tick chọn mẫu đầu tiên nếu có dữ liệu
      if (_allTemplates.isNotEmpty && selectedTemplateId == null) {
        selectedTemplateId = _allTemplates.first.id;
      }

      _applyLocalSearch();
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoading = false;
      notifyListeners();
    }
  }

  // Khi chọn Radio button
  void selectTemplate(String id) {
    if (selectedTemplateId != id) {
      selectedTemplateId = id;
      notifyListeners();
    }
  }

  // Khi gõ text tìm kiếm
  void onSearchChanged(String query) {
    searchQuery = query;
    _applyLocalSearch();
  }

  void _applyLocalSearch() {
    if (searchQuery.trim().isEmpty) {
      displayedTemplates = List.from(_allTemplates);
    } else {
      final query = searchQuery.trim().toLowerCase();
      displayedTemplates = _allTemplates.where((template) {
        return template.name.toLowerCase().contains(query);
      }).toList();
    }
    isLoading = false;
    notifyListeners();
  }

  // --- Hàm cập nhật cục bộ trên RAM (để đồng nhất với cấu trúc app) ---
  void addLocalTemplate(ContractTemplateResponse newTemplate) {
    _allTemplates.insert(0, newTemplate);
    _applyLocalSearch();
  }
}