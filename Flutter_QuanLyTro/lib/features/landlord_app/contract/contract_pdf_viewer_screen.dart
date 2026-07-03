import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class ContractPdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String roomNumber;

  const ContractPdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.roomNumber,
  });

  @override
  State<ContractPdfViewerScreen> createState() => _ContractPdfViewerScreenState();
}

class _ContractPdfViewerScreenState extends State<ContractPdfViewerScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      
      appBar: CustomAppBar(title: 'Hợp đồng phòng ${widget.roomNumber}'),

      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.pdfUrl,
            key: _pdfViewerKey,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                _isLoading = false;
              });
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Không thể tải PDF: ${details.description}';
              });
            },
          ),

          if (_isLoading && _errorMessage == null)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}