import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/session.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({String? baseUrl})
    : baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_URL',
            defaultValue: 'http://localhost:3000/api/v1',
          );
  final String baseUrl;

  Future<Session> login({
    required String clientCode,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'clientCode': clientCode,
        'email': email,
        'password': password,
      }),
    );
    final body = _decode(response);
    return Session(
      accessToken: body['accessToken'] as String,
      userName: (body['user'] as Map<String, dynamic>)['name'] as String,
      userId: (body['user'] as Map<String, dynamic>)['id'] as String?,
      roles: List<String>.from(
        ((body['user'] as Map<String, dynamic>)['roles'] as List?) ?? const [],
      ),
    );
  }

  Future<http.Response> getExamFile(
    String examId,
    String token, {
    bool download = false,
  }) async {
    final action = download ? '/download' : '';

    final response = await http.get(
      Uri.parse('$baseUrl/exams/$examId/file$action'),
      headers: {
        'authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'No fue posible obtener el documento del examen.',
        response.statusCode,
      );
    }

    return response;
  }
  Future<Map<String, dynamic>> getJson(String path, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {'authorization': 'Bearer $token'},
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: {
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> uploadExamFile({
    required String examId,
    required String token,
    required String fileName,
    required List<int> bytes,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/exams/$examId/file'),
    )..headers['authorization'] = 'Bearer $token';
    final extension = fileName.split('.').last.toLowerCase();
    final mediaType = switch (extension) {
      'pdf' => MediaType('application', 'pdf'),
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png' => MediaType('image', 'png'),
      _ => MediaType('application', 'octet-stream'),
    };
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: mediaType,
      ),
    );
    final streamed = await request.send();
    return _decode(await http.Response.fromStream(streamed));
  }

  Future<Map<String, dynamic>> initiateClinicalTest({
    required String token,
    required String clientUploadId,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required String sha256,
    required String testType,
    required String title,
    required String testDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/clinical-tests/uploads/initiate'),
      headers: {
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
        'Idempotency-Key': clientUploadId,
      },
      body: jsonEncode({
        'client_upload_id': clientUploadId,
        'file_name': fileName,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
        'sha256': sha256,
        'test_type': testType,
        'title': title,
        'test_date': testDate,
      }),
    );
    return _decode(response);
  }

  Future<void> putSignedFile(
    String url,
    Map<String, dynamic> headers,
    List<int> bytes,
  ) async {
    final response = await http.put(
      Uri.parse(url),
      headers: headers.map((key, value) => MapEntry(key, '$value')),
      body: bytes,
    );
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw ApiException(
        'No fue posible guardar el archivo de forma segura.',
        response.statusCode,
      );
  }

  Future<Map<String, dynamic>> refreshClinicalTestUploadUrl({
    required String token,
    required String uploadId,
    required String clientUploadId,
    required String sha256,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/clinical-tests/uploads/$uploadId/refresh-url'),
      headers: {
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
        'Idempotency-Key': clientUploadId,
      },
      body: jsonEncode({'client_upload_id': clientUploadId, 'sha256': sha256}),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> completeClinicalTest({
    required String token,
    required String uploadId,
    required String clientUploadId,
    required String sha256,
    required int sizeBytes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/clinical-tests/uploads/$uploadId/complete'),
      headers: {
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
        'Idempotency-Key': clientUploadId,
      },
      body: jsonEncode({
        'client_upload_id': clientUploadId,
        'sha256': sha256,
        'size_bytes': sizeBytes,
      }),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> clinicalTestStatus(
    String uploadId,
    String token,
  ) => getJson('/clinical-tests/uploads/' + uploadId + '/status', token);

  Future<Map<String, dynamic>> listClinicalTests(String token) =>
      getJson('/clinical-tests/', token);
  Future<Map<String, dynamic>> clinicalTestDownloadUrl(
    String id,
    String token, {
    String disposition = 'attachment',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/clinical-tests/$id/download-url'),
      headers: {
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode({'disposition': disposition}),
    );
    return _decode(response);
  }

  Future<void> delete(String path, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: {'authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _decode(response);
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'] as Map<String, dynamic>?;
      throw ApiException(
        error?['message'] as String? ??
            'No fue posible completar la solicitud.',
        response.statusCode,
      );
    }
    return decoded;
  }
}

