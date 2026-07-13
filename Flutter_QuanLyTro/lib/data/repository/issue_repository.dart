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
}