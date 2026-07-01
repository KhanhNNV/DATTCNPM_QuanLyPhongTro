import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class ContractPdfViewerScreen extends StatelessWidget {
  final String pdfUrl;
  final String roomNumber;

  const ContractPdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.roomNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Hợp đồng phòng $roomNumber'),
      body: SfPdfViewer.network(
        pdfUrl,
        canShowScrollHead: false,
        canShowScrollStatus: false,
        // Hiển thị vòng xoay loading trong lúc tải file từ internet
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải PDF: ${details.description}')),
          );
        },
      ),
    );
  }
}