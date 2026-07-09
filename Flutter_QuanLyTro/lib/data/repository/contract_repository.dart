import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../models/request/contract_create_manual_request.dart';
import '../models/request/contract_create_request.dart';
import '../models/request/contract_member_add_request.dart';
import '../models/response/contract_create_response.dart';
import '../models/response/contract_detail_response.dart';
import '../../../core/utils/api_error_handler.dart';

class ContractRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ContractCreateResponse> createContractOcr({
    required ContractCreateRequest dataRequest,
    required File frontImage,
    required File backImage,
  }) async {
    final response = await _apiClient.postMultipart(
      '/api/contracts/create',
      fields: {
        'data': dataRequest.toJson(),
      },
      files: {
        'frontImage': frontImage,
        'backImage': backImage,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return ContractCreateResponse.fromJson(json);
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<ContractCreateResponse> createContractManual(ContractCreateManualRequest request) async {
    final response = await _apiClient.post(
      '/api/contracts/create/manual',
      request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return ContractCreateResponse.fromJson(json);
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<List<ContractDetailResponse>> getMyContracts() async {
    final response = await _apiClient.get('/api/contracts');

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonList.map((json) => ContractDetailResponse.fromJson(json)).toList();
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<ContractDetailResponse> getContractDetail(String contractId) async {
    final response = await _apiClient.get('/api/contracts/$contractId');

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return ContractDetailResponse.fromJson(json);
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<ContractDetailResponse> uploadContractFile(String contractId, File file) async {
    final response = await _apiClient.postMultipart(
      '/api/contracts/upload/file/$contractId',
      fields: {},
      files: {
        'file': file,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return ContractDetailResponse.fromJson(json);
    }

    // Ném lỗi qua Handler
    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<String> deleteContract(String contractId) async {
    final response = await _apiClient.delete('/api/contracts/$contractId');

    if (response.statusCode == 200) {
      return utf8.decode(response.bodyBytes);
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<ContractDetailResponse> updateContract({
    required String contractId,
    required Map<String, dynamic> data,
    File? file,
  }) async {
    final endpoint = '/api/contracts/update/$contractId';

    final Map<String, String> fields = {
      'data': jsonEncode(data),
    };

    final Map<String, File> files = {};
    if (file != null) {
      files['file'] = file;
    }
    
    final response = await _apiClient.putMultipartForm(
      endpoint,
      fields: fields,
      files: files.isNotEmpty ? files : null,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return ContractDetailResponse.fromJson(json);
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<ContractDetailResponse> getMyCurrentContract() async {
    final response = await _apiClient.get('/api/contracts/current');

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return ContractDetailResponse.fromJson(json);
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }


  Future<ContractDetailResponse> signContract({
    required String contractId,
    required Uint8List signatureBytes,
    File? pdfFile,
  }) async {
    final endpoint = '/api/contracts/sign/$contractId';

    // Tạo file tạm cho chữ ký từ Uint8List vì putMultipartForm yêu cầu kiểu dữ liệu File
    final tempDir = Directory.systemTemp;
    final signatureFile = File('${tempDir.path}/sig_$contractId.png');
    await signatureFile.writeAsBytes(signatureBytes);

    final Map<String, File> files = {
      'signature': signatureFile,
    };

    if (pdfFile != null) {
      files['file'] = pdfFile;
    }

    try {
      final response = await _apiClient.putMultipartForm(
        endpoint,
        fields: {},
        files: files,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        return ContractDetailResponse.fromJson(json);
      }

      final rawError = utf8.decode(response.bodyBytes);
      throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
    } finally {
      // dọn dẹp file chữ ký tạm sau khi request chạy xong
      if (await signatureFile.exists()) {
        await signatureFile.delete();
      }
    }
  }

  Future<ContractDetailResponse> addContractMember(ContractMemberAddRequest request) async {
    final response = await _apiClient.post(
      '/api/contracts/add/member',
      request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return ContractDetailResponse.fromJson(json);
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }
}