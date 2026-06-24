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
  final contentController = TextEditingController();

  bool isLoading = false;

  // --- HÀM XỬ LÝ DỮ LIỆU ĐỘNG ---
  // Nếu có dữ liệu thì hiển thị, nếu không có thì hiển thị chuỗi dấu chấm
  String _formatData(String? value, int dotLength) {
    if (value != null && value.trim().isNotEmpty) {
      return value;
    }
    return '.' * dotLength;
  }

  // --- HÀM TẠO PDF ---
  // Hỗ trợ truyền tham số tuỳ chọn.
  // Lúc xem trước mẫu không truyền gì -> Tự ra dấu chấm.
  // Lúc xuất hợp đồng thật -> Truyền data thật vào đây.
  Future<Uint8List> generatePdfBytes({
    String? ngayKy,
    String? thangKy,
    String? namKy,
    String? diaChiKy,
    String? tenBenA,
    String? cccdBenA,
    String? ngayCapCccdBenA,
    String? noiCapCccdBenA,
    String? thuongTruBenA,
    String? tenBenB,
    String? cccdBenB,
    String? ngayCapCccdBenB,
    String? noiCapCccdBenB,
    String? thuongTruBenB,
  }) async {
    final userText = contentController.text.trim();
    if (userText.isEmpty) {
      throw Exception('Vui lòng nhập nội dung hợp đồng trước khi xem trực tiếp!');
    }

    final notoSerifRegular = await PdfGoogleFonts.notoSerifRegular();
    final notoSerifBold = await PdfGoogleFonts.notoSerifBold();

    final pdf = pw.Document();
    final List<String> userLines = userText.split('\n');

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
                nameController.text.isNotEmpty
                    ? nameController.text.toUpperCase()
                    : 'HỢP ĐỒNG THUÊ PHÒNG TRỌ',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 24),

            pw.Text(
                'Hôm nay, ngày ${_formatData(ngayKy, 6)} tháng ${_formatData(thangKy, 6)} năm ${_formatData(namKy, 8)}, tại địa chỉ: ${_formatData(diaChiKy, 45)}. Chúng tôi gồm có:',
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 3)
            ),
            pw.SizedBox(height: 16),

            // --- THÔNG TIN BÊN A ---
            pw.Text('BÊN CHO THUÊ PHÒNG TRỌ (gọi tắt là Bên A):', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Ông/bà: ${_formatData(tenBenA, 40)}', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 6),
            pw.Text('CMND/CCCD số: ${_formatData(cccdBenA, 25)}   cấp ngày: ${_formatData(ngayCapCccdBenA, 20)}   nơi cấp: ${_formatData(noiCapCccdBenA, 30)}', style: const pw.TextStyle(fontSize: 12, lineSpacing: 2)),
            pw.SizedBox(height: 6),
            pw.Text('Thường trú tại: ${_formatData(thuongTruBenA, 65)}', style: const pw.TextStyle(fontSize: 12, lineSpacing: 2)),
            pw.SizedBox(height: 16),

            // --- THÔNG TIN BÊN B ---
            pw.Text('BÊN THUÊ PHÒNG TRỌ (gọi tắt là Bên B):', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Ông/bà: ${_formatData(tenBenB, 40)}', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 6),
            pw.Text('CMND/CCCD số: ${_formatData(cccdBenB, 25)}   cấp ngày: ${_formatData(ngayCapCccdBenB, 20)}   nơi cấp: ${_formatData(noiCapCccdBenB, 30)}', style: const pw.TextStyle(fontSize: 12, lineSpacing: 2)),
            pw.SizedBox(height: 6),
            pw.Text('Thường trú tại: ${_formatData(thuongTruBenB, 65)}', style: const pw.TextStyle(fontSize: 12, lineSpacing: 2)),
            pw.SizedBox(height: 20),

            pw.Text('Sau khi thỏa thuận, hai bên thống nhất các điều khoản sau:', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 12),

            // --- NỘI DUNG ĐIỀU KHOẢN ---
            ...userLines.map((line) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Text(
                  line,
                  style: const pw.TextStyle(fontSize: 12, lineSpacing: 3.5),
                  textAlign: pw.TextAlign.justify,
                ),
              );
            }),
            pw.SizedBox(height: 36),

            // --- CHỮ KÝ ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Bên B', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Text('(Ký, ghi rõ họ tên)', style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Bên A', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Text('(Ký, ghi rõ họ tên)', style: const pw.TextStyle(fontSize: 11)),
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

  Future<void> previewPdf() async {
    isLoading = true;
    notifyListeners();
    try {
      final pdfBytes = await generatePdfBytes(); // Hiện tại không truyền data -> ra dấu chấm
      final String? filePath = await FileSaver.instance.saveAs(
        name: 'Hop_Dong_Thue_Phong_${DateTime.now().millisecondsSinceEpoch}.pdf',
        bytes: pdfBytes,
        mimeType: MimeType.pdf,
      );
      if (filePath != null) {
        print("Lưu thành công: $filePath");
      }
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<ContractTemplateResponse> saveTemplate() async {
    if (!formKey.currentState!.validate()) {
      throw Exception('Vui lòng điền đầy đủ thông tin hợp lệ!');
    }
    final rawText = contentController.text.trim();
    if (rawText.isEmpty) {
      throw Exception('Vui lòng nhập nội dung hợp đồng!');
    }
    try {
      isLoading = true;
      notifyListeners();

      final request = ContractTemplateRequest(
        name: nameController.text.trim(),
        content: rawText,
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
    contentController.dispose();
    super.dispose();
  }
}