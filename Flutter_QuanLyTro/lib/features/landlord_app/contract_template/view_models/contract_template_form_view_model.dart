import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
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

  void insertPlaceholder(String placeholder) {
    final text = contentController.text;
    final selection = contentController.selection;

    if (selection.baseOffset == -1 || selection.extentOffset == -1) {
      contentController.text = text + placeholder;
      contentController.selection = TextSelection.collapsed(
          offset: contentController.text.length);
    } else {
      final newText = text.replaceRange(selection.start, selection.end, placeholder);
      contentController.text = newText;
      contentController.selection = TextSelection.collapsed(
          offset: selection.start + placeholder.length);
    }
    notifyListeners();
  }

  String get simulatedPreviewText {
    final rawText = contentController.text.trim();
    if (rawText.isEmpty) return '';

    return rawText
        .replaceAll('{{TEN_KHACH}}', 'NGUYỄN VĂN A')
        .replaceAll('{{SDT_KHACH}}', '0987.654.321')
        .replaceAll('{{CCCD_KHACH}}', '001095001234')
        .replaceAll('{{TEN_PHONG}}', 'Phòng 302 (Tầng 3)')
        .replaceAll('{{GIA_THUE}}', '3,500,000 đ/tháng')
        .replaceAll('{{TIEN_COC}}', '3,500,000 đ')
        .replaceAll('{{NGAY_BAT_DAU}}', '22/06/2026');
  }

  Future<void> previewPdf() async {
    final userText = simulatedPreviewText;
    if (userText.isEmpty) {
      throw Exception('Vui lòng nhập nội dung hợp đồng trước khi xuất PDF!');
    }

    isLoading = true;
    notifyListeners();

    try {
      final robotoRegular = await PdfGoogleFonts.robotoRegular();
      final robotoBold = await PdfGoogleFonts.robotoBold();

      final pdf = pw.Document();
      final List<String> userLines = userText.split('\n');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          theme: pw.ThemeData.withFont(base: robotoRegular, bold: robotoBold),
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text('Độc lập – Tự do – Hạnh phúc', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Container(width: 140, height: 1, color: PdfColors.black),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              pw.Center(
                child: pw.Text(
                  nameController.text.isNotEmpty
                      ? nameController.text.toUpperCase()
                      : 'HỢP ĐỒNG THUÊ PHÒNG TRỌ',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),

              // ĐÃ BỎ CÁC DẤU CHẤM VÀ THAY BẰNG DỮ LIỆU GIẢ LẬP ĐỂ XEM TRƯỚC
              pw.Text('Hôm nay, ngày 22 tháng 06 năm 2026, tại căn nhà số: 123 Đường ABC, Phường X, Quận Y. Chúng tôi gồm có:', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 12),

              pw.Text('BÊN CHO THUÊ PHÒNG TRỌ (gọi tắt là Bên A):', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('Ông/bà: TRẦN VĂN CHỦ', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('CMND/CCCD số: 079090000123   cấp ngày: 01/01/2021   nơi cấp: Cục Cảnh sát QLHC về TTXH', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Thường trú tại: 123 Đường ABC, Phường X, Quận Y, TP.HCM', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 12),

              pw.Text('BÊN THUÊ PHÒNG TRỌ (gọi tắt là Bên B):', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('Ông/bà: NGUYỄN VĂN A', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('CMND/CCCD số: 001095001234   cấp ngày: 15/05/2022   nơi cấp: Cục Cảnh sát QLHC về TTXH', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Thường trú tại: 456 Đường DEF, Phường Z, Quận W, TP.HCM', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 16),

              pw.Text('Sau khi thỏa thuận, hai bên thống nhất như sau:', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 12),

              ...userLines.map((line) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Text(
                    line,
                    style: const pw.TextStyle(fontSize: 12),
                    textAlign: pw.TextAlign.justify,
                  ),
                );
              }),
              pw.SizedBox(height: 32),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Bên B', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('(Ký, ghi rõ họ tên)', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Bên A', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('(Ký, ghi rõ họ tên)', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();

      final String? filePath = await FileSaver.instance.saveAs(
        // Thêm trực tiếp đuôi .pdf vào cuối tên file ở đây
        name: 'Hop_Dong_Thue_Phong_${DateTime.now().millisecondsSinceEpoch}.pdf',
        bytes: pdfBytes,
        mimeType: MimeType.pdf,
      );

      if (filePath != null) {
        print("Lưu lên Google Drive/Bộ nhớ thành công: $filePath");
      } else {
        print("User đã bấm Hủy.");
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