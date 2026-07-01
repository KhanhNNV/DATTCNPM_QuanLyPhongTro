import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import '../../../../core/constants/app_colors.dart';

class ContractTemplatePreviewScreen extends StatefulWidget {
  final String templateName;
  final String rentalContent;
  final String landlordDuty;
  final String tenantDuty;
  final String executionTerms;

  const ContractTemplatePreviewScreen({
    super.key,
    required this.templateName,
    required this.rentalContent,
    required this.landlordDuty,
    required this.tenantDuty,
    required this.executionTerms,
  });

  @override
  State<ContractTemplatePreviewScreen> createState() => _ContractTemplatePreviewScreenState();
}

class _ContractTemplatePreviewScreenState extends State<ContractTemplatePreviewScreen> {
  late Future<Uint8List> _pdfBytesFuture;
  Uint8List? _cachedBytes;

  @override
  void initState() {
    super.initState();
    _pdfBytesFuture = _generatePdfBytes();
  }

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

  Future<Uint8List> _generatePdfBytes() async {
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
                'HỢP ĐỒNG THUÊ PHÒNG TRỌ',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Text(
                'Hôm nay, ngày ${_formatData(null, 6)} tháng ${_formatData(null, 6)} năm ${_formatData(null, 8)}, tại địa chỉ: ${_formatData(null, 45)}. Chúng tôi gồm có:',
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 3)
            ),
            pw.SizedBox(height: 16),
            pw.Text('BÊN CHO THUÊ PHÒNG TRỌ (gọi tắt là Bên A):', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Ông/bà: ${_formatData(null, 40)}', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 6),
            pw.Text('CMND/CCCD số: ${_formatData(null, 25)}   cấp ngày: ${_formatData(null, 20)}   nơi cấp: ${_formatData(null, 30)}', style: const pw.TextStyle(fontSize: 12, lineSpacing: 2)),
            pw.SizedBox(height: 6),
            pw.Text('Thường trú tại: ${_formatData(null, 65)}', style: const pw.TextStyle(fontSize: 12, lineSpacing: 2)),
            pw.SizedBox(height: 16),
            pw.Text('BÊN THUÊ PHÒNG TRỌ (gọi tắt là Bên B):', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Ông/bà: ${_formatData(null, 40)}', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 6),
            pw.Text('CMND/CCCD số: ${_formatData(null, 25)}   cấp ngày: ${_formatData(null, 20)}   nơi cấp: ${_formatData(null, 30)}', style: const pw.TextStyle(fontSize: 12, lineSpacing: 2)),
            pw.SizedBox(height: 6),
            pw.Text('Thường trú tại: ${_formatData(null, 65)}', style: const pw.TextStyle(fontSize: 12, lineSpacing: 2)),
            pw.SizedBox(height: 20),
            pw.Text('Sau khi thỏa thuận, hai bên thống nhất các điều khoản sau:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold,)),
            pw.SizedBox(height: 12),

            _buildSection('1. Nội dung thuê phòng trọ', widget.rentalContent),
            _buildSection('2. Trách nhiệm Bên A', widget.landlordDuty),
            _buildSection('3. Trách nhiệm Bên B', widget.tenantDuty),
            _buildSection('4. Điều khoản thực hiện', widget.executionTerms),

            pw.SizedBox(height: 36),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Bên B', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Text('(Ký, ghi rõ họ tên)', style: const pw.TextStyle(fontSize: 11,)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Bên A', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Text('(Ký, ghi rõ họ tên)', style: const pw.TextStyle(fontSize: 11,)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Bản xem trước hợp đồng', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: _cachedBytes == null
                ? null
                : () async {
              try {
                // ĐÃ SỬA: Lưu xuống thiết bị và hiển thị thông báo.
                final fileName = 'Mau_Hop_Dong_${DateTime.now().millisecondsSinceEpoch}.pdf';
                await FileSaver.instance.saveAs(
                  name: fileName,
                  bytes: _cachedBytes!,
                  mimeType: MimeType.pdf,
                );

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã lưu file PDF xuống máy thành công!'), backgroundColor: Colors.green),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi lưu file: $e'), backgroundColor: Colors.redAccent),
                );
              }
            },
            icon: const Icon(Icons.download, color: Colors.white, size: 18),
            label: const Text('LƯU MÁY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfBytesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Không thể khởi tạo bản xem trước PDF:\n${snapshot.error.toString().replaceAll('Exception: ', '')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ),
            );
          }
          if (snapshot.hasData) {
            _cachedBytes = snapshot.data;
            return SfPdfViewer.memory(
              _cachedBytes!,
              canShowScrollHead: true,
              canShowScrollStatus: true,
            );
          }
          return const Center(child: Text('Không có dữ liệu văn bản.'));
        },
      ),
    );
  }
}