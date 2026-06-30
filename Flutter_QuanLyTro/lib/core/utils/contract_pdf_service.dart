import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_quanlytro/core/utils/template_compiler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:number_to_vietnamese_words/number_to_vietnamese_words.dart';

class ContractPdfService {
  static Future<Uint8List> generateContractPdf({
    required String templateName,
    required String rentalContent,
    required String landlordDuty,
    required String tenantDuty,
    required String executionTerms,

    required String landlordName,
    required String landlordIdCard,
    required String landlordAddress,

    required String tenantName,
    required String tenantIdCard,
    required String tenantAddress,

    required String roomAddress,
    required DateTime createdDate,
    String? landlordSignatureUrl,

    // CÁC TRƯỜNG THÊM VÀO ĐỂ REPLACE
    required String roomNumber,
    required double rentPrice,
    required double depositAmount,
    required int durationMonths,
    required int paymentDay,
  }) async {

    // 1. CHUẨN BỊ DỮ LIỆU ĐỂ REPLACE
    final Map<String, dynamic> realData = {
      'SO_PHONG': roomNumber,
      'DIA_CHI_NHA': roomAddress,
      'THOI_HAN': durationMonths.toString(),
      'GIA_THUE': TemplateCompiler.formatCurrency(rentPrice),
      'GIA_THUE_CHU': rentPrice.toInt().toVietnameseWords(),
      'TIEN_COC': TemplateCompiler.formatCurrency(depositAmount),
      'TIEN_COC_CHU': depositAmount.toInt().toVietnameseWords(),
      'NGAY_THANH_TOAN': paymentDay.toString().padLeft(2, '0'),
    };

    // 2. BIÊN DỊCH NỘI DUNG TỪ TEMPLATE SANG TEXT THẬT
    final finalRentalContent = TemplateCompiler.compileText(rentalContent, realData);
    final finalLandlordDuty = TemplateCompiler.compileText(landlordDuty, realData);
    final finalTenantDuty = TemplateCompiler.compileText(tenantDuty, realData);
    final finalExecutionTerms = TemplateCompiler.compileText(executionTerms, realData);

    // 3. VẼ PDF
    final notoSerifRegular = await PdfGoogleFonts.notoSerifRegular();
    final notoSerifBold = await PdfGoogleFonts.notoSerifBold();
    final pdf = pw.Document();

    pw.ImageProvider? landlordSignatureImage;
    if (landlordSignatureUrl != null && landlordSignatureUrl.isNotEmpty) {
      try {
        landlordSignatureImage = await networkImage(landlordSignatureUrl);
      } catch (e) {
        debugPrint('Không thể tải chữ ký: $e');
      }
    }

    pw.Widget buildSection(String title, String content) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          ...content.split('\n').map((line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(line, style: const pw.TextStyle(fontSize: 12, lineSpacing: 3.5), textAlign: pw.TextAlign.justify),
          )),
          pw.SizedBox(height: 12),
        ],
      );
    }

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
                'HỢP ĐỒNG THUÊ PHÒNG TRỌ',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Text(
                'Hôm nay, ngày ${createdDate.day} tháng ${createdDate.month} năm ${createdDate.year}, tại địa chỉ: $roomAddress. Chúng tôi gồm có:',
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 3)
            ),
            pw.SizedBox(height: 16),
            pw.Text('BÊN CHO THUÊ PHÒNG TRỌ (gọi tắt là Bên A):', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Ông/bà: $landlordName', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 6),
            pw.Text('CMND/CCCD số: $landlordIdCard', style: const pw.TextStyle(fontSize: 12, lineSpacing: 2)),
            pw.SizedBox(height: 6),
            pw.Text('Thường trú tại: $landlordAddress', style: const pw.TextStyle(fontSize: 12, lineSpacing: 2)),
            pw.SizedBox(height: 16),
            pw.Text('BÊN THUÊ PHÒNG TRỌ (gọi tắt là Bên B):', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Ông/bà: $tenantName', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 6),
            pw.Text('CMND/CCCD số: $tenantIdCard', style: const pw.TextStyle(fontSize: 12, lineSpacing: 2)),
            pw.SizedBox(height: 6),
            pw.Text('Thường trú tại: $tenantAddress', style: const pw.TextStyle(fontSize: 12, lineSpacing: 2)),
            pw.SizedBox(height: 20),
            pw.Text('Sau khi thỏa thuận, hai bên thống nhất các điều khoản sau:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),

            // SỬ DỤNG CÁC TEXT ĐÃ ĐƯỢC REPLACE Ở ĐÂY
            buildSection('1. Nội dung thuê phòng trọ', finalRentalContent),
            buildSection('2. Trách nhiệm Bên A', finalLandlordDuty),
            buildSection('3. Trách nhiệm Bên B', finalTenantDuty),
            buildSection('4. Điều khoản thực hiện', finalExecutionTerms),

            pw.SizedBox(height: 36),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Bên B', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Text('(Ký, ghi rõ họ tên)', style: const pw.TextStyle(fontSize: 11)),
                    pw.SizedBox(height: 50),
                    pw.Text(tenantName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Bên A', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Text('(Ký, ghi rõ họ tên)', style: const pw.TextStyle(fontSize: 11)),
                    pw.SizedBox(height: 10),
                    if (landlordSignatureImage != null)
                      pw.Image(landlordSignatureImage, height: 60, width: 100, fit: pw.BoxFit.contain)
                    else
                      pw.SizedBox(height: 60),
                    pw.Text(landlordName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
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
}