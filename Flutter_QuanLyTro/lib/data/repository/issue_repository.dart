import 'dart:convert';
import 'dart:io';
import '../../../core/network/api_client.dart';
import '../../core/utils/api_error_handler.dart';
import '../models/response/issue_response.dart';

class IssueRepository {
  final ApiClient _apiClient = ApiClient();

  Future<IssueResponse> reportIssue({
    required String roomId,
    required String description,
    File? image,
  }) async {
    final path = '/api/issues';

    final Map<String, String> fields = {
      'roomId': roomId,
      'description': description,
    };

    final Map<String, File> files = {};
    if (image != null) {
      files['image'] = image;
    }

    final response = await _apiClient.postMultipart(
      path,
      fields: fields,
      files: files,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
      return IssueResponse.fromJson(responseData);
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<Map<String, dynamic>> getMyIssues({
    required int page,
    required int size,
    String? status,
  }) async {
    String path = '/api/issues/tenant?page=$page&size=$size';
    if (status != null) {
      path += '&status=$status';
    }

    final response = await _apiClient.get(path);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<Map<String, dynamic>> getIssuesForLandlord({
    required int page,
    required int size,
    String? status,
    String? roomId,
  }) async {
    String path = '/api/issues/landlord?page=$page&size=$size';

    if (status != null) {
      path += '&status=$status';
    }
    if (roomId != null) {
      path += '&roomId=$roomId';
    }

    final response = await _apiClient.get(path);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }

  Future<IssueResponse> updateIssueStatus({
    required String issueId,
    required String status,
    String? solutionNote,
  }) async {
    String path = '/api/issues/$issueId/status?status=$status';
    if (solutionNote != null && solutionNote.trim().isNotEmpty) {
      path += '&solutionNote=${Uri.encodeComponent(solutionNote)}';
    }

    final response = await _apiClient.put(path,{});

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
      return IssueResponse.fromJson(responseData);
    }

    final rawError = utf8.decode(response.bodyBytes);
    throw Exception(ApiErrorHandler.extractErrorMessage(rawError));
  }
}