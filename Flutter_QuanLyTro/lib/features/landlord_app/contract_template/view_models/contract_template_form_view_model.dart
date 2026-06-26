import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../data/models/request/contract_template_request.dart';
import '../../../../data/models/response/contract_template_response.dart';
import '../../../../data/repository/contract_template_repository.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';

class ContractTemplateFormViewModel extends ChangeNotifier {
  final ContractTemplateRepository _repository = ContractTemplateRepository();

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();

  // ĐÃ SỬA: Thay thế dấu chấm thành các biến {{...}}
  final rentalContentController = TextEditingController(
      text: 'Bên A cho Bên B thuê 01 phòng trọ số {{SO_PHONG}} tại căn nhà số {{DIA_CHI_NHA}}. '
          'Với thời hạn là: {{THOI_HAN}} tháng, giá thuê: {{GIA_THUE}} đồng (Bằng chữ: {{GIA_THUE_CHU}}). '
          'Chưa bao gồm chi phí: điện sinh hoạt, nước.'
  );

  final landlordDutyController = TextEditingController(
      text: '- Đảm bảo căn nhà cho thuê không có tranh chấp, khiếu kiện.\n'
          '- Đăng ký với chính quyền địa phương về thủ tục cho thuê phòng trọ.'
  );

  final tenantDutyController = TextEditingController(
      text: '- Đặt cọc với số tiền là: {{TIEN_COC}} đồng (Bằng chữ: {{TIEN_COC_CHU}}), thanh toán tiền thuê phòng hàng tháng vào ngày {{NGAY_THANH_TOAN}} + tiền điện + nước.\n'
          '- Đảm bảo các thiết bị và sửa chữa các hư hỏng trong phòng trong khi sử dụng. Nếu không sửa chữa thì khi trả phòng, bên A sẽ trừ vào tiền đặt cọc, giá trị cụ thể được tính theo giá thị trường.\n'
          '- Chỉ sử dụng phòng trọ vào mục đích ở, với số lượng tối đa không quá 04 người (kể cả trẻ em); không chứa các thiết bị gây cháy nổ, hàng cấm... cung cấp giấy tờ tùy thân để đăng ký tạm trú theo quy định, giữ gìn an ninh trật tự, nếp sống văn hóa đô thị; không tụ tập nhậu nhẹt, cờ bạc và các hành vi vi phạm pháp luật khác.\n'
          '- Không được tự ý cải tạo kiếm trúc phòng hoặc trang trí ảnh hưởng tới tường, cột, nền... Nếu có nhu cầu trên phải trao đổi với bên A để được thống nhất.'
  );

  final executionTermsController = TextEditingController(
      text: '- Hai bên nghiêm túc thực hiện những quy định trên trong thời hạn cho thuê, nếu bên A lấy phòng phải báo cho bên B ít nhất 01 tháng, hoặc ngược lại.\n'
          '- Sau thời hạn cho thuê {{THOI_HAN}} tháng nếu bên B có nhu cầu hai bên tiếp tục thương lượng giá thuê để gia hạn hợp đồng bằng miệng hoặc thực hiện ký gia hạn mới.'
  );

  bool isLoading = false;

  String _formatData(String? value, int dotLength) {
    if (value != null && value.trim().isNotEmpty) return value;
    return '.' * dotLength;
  }

  pw.Widget _buildSection(String title, String content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        ...content.split('\n').map((line) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(
              line,
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 3.5),
              textAlign: pw.TextAlign.justify,
            ),
          );
        }),
        pw.SizedBox(height: 12),
      ],
    );
  }

  Future<Uint8List> generatePdfBytes({
    String? ngayKy, String? thangKy, String? namKy, String? diaChiKy,
    String? tenBenA, String? cccdBenA, String? ngayCapCccdBenA, String? noiCapCccdBenA, String? thuongTruBenA,
    String? tenBenB, String? cccdBenB, String? ngayCapCccdBenB, String? noiCapCccdBenB, String? thuongTruBenB,
  }) async {
    final notoSerifRegular = await PdfGoogleFonts.notoSerifRegular();
    final notoSerifBold = await PdfGoogleFonts.notoSerifBold();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: notoSerifRegular, bold: notoSerifBold),
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Độc lập – Tự do – Hạnh phúc', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Container(width: 140, height: 1, color: PdfColors.black),
                ],
              ),
            ),
            pw.SizedBox(height: 28),
            pw.Center(
              child: pw.Text(
                nameController.text.isNotEmpty ? nameController.text.toUpperCase() : 'HỢP ĐỒNG THUÊ PHÒNG TRỌ',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Text(
                'Hôm nay, ngày ${_formatData(ngayKy, 6)} tháng ${_formatData(thangKy, 6)} năm ${_formatData(namKy, 8)}, tại địa chỉ: ${_formatData(diaChiKy, 45)}. Chúng tôi gồm có:',
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 3)
            ),
            pw.SizedBox(height: 16),
            pw.Text('BÊN CHO THUÊ PHÒNG TRỌ (gọi tắt là Bên A):', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Ông/bà: ${_formatData(tenBenA, 40)}', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 6),
            pw.Text('CMND/CCCD số: ${_formatData(cccdBenA, 25)}   cấp ngày: ${_formatData(ngayCapCccdBenA, 20)}   nơi cấp: ${_formatData(noiCapCccdBenA, 30)}', style: const pw.TextStyle(fontSize: 12, lineSpacing: 2)),
            pw.SizedBox(height: 6),
            pw.Text('Thường trú tại: ${_formatData(thuongTruBenA, 65)}', style: const pw.TextStyle(fontSize: 12, lineSpacing: 2)),
            pw.SizedBox(height: 16),
            pw.Text('BÊN THUÊ PHÒNG TRỌ (gọi tắt là Bên B):', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Ông/bà: ${_formatData(tenBenB, 40)}', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 6),
            pw.Text('CMND/CCCD số: ${_formatData(cccdBenB, 25)}   cấp ngày: ${_formatData(ngayCapCccdBenB, 20)}   nơi cấp: ${_formatData(noiCapCccdBenB, 30)}', style: const pw.TextStyle(fontSize: 12, lineSpacing: 2)),
            pw.SizedBox(height: 6),
            pw.Text('Thường trú tại: ${_formatData(thuongTruBenB, 65)}', style: const pw.TextStyle(fontSize: 12, lineSpacing: 2)),
            pw.SizedBox(height: 20),
            pw.Text('Sau khi thỏa thuận, hai bên thống nhất các điều khoản sau:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic)),
            pw.SizedBox(height: 12),
            _buildSection('1. Nội dung thuê phòng trọ', rentalContentController.text),
            _buildSection('2. Trách nhiệm Bên A', landlordDutyController.text),
            _buildSection('3. Trách nhiệm Bên B', tenantDutyController.text),
            _buildSection('4. Điều khoản thực hiện', executionTermsController.text),
            pw.SizedBox(height: 36),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Bên B', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Text('(Ký, ghi rõ họ tên)', style: const pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Bên A', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Text('(Ký, ghi rõ họ tên)', style: const pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  Future<ContractTemplateResponse> saveTemplate() async {
    if (!formKey.currentState!.validate()) {
      throw Exception('Vui lòng điền đầy đủ thông tin hợp lệ!');
    }

    try {
      isLoading = true;
      notifyListeners();

      final request = ContractTemplateRequest(
        name: nameController.text.trim(),
        rentalContent: rentalContentController.text.trim(),
        landlordDuty: landlordDutyController.text.trim(),
        tenantDuty: tenantDutyController.text.trim(),
        executionTerms: executionTermsController.text.trim(),
      );

      final createdTemplate = await _repository.createTemplate(request);

      isLoading = false;
      notifyListeners();
      return createdTemplate;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    rentalContentController.dispose();
    landlordDutyController.dispose();
    tenantDutyController.dispose();
    executionTermsController.dispose();
    super.dispose();
  }
}