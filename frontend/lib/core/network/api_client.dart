import 'package:dio/dio.dart';

import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    required Future<String?> Function() tokenProvider,
  }) : _tokenProvider = tokenProvider,
       _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 45),
           receiveTimeout: const Duration(seconds: 90),
           sendTimeout: const Duration(seconds: 90),
           headers: const {'Content-Type': 'application/json'},
         ),
       ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenProvider();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (exception, handler) {
          handler.reject(_mapException(exception));
        },
      ),
    );
  }

  final Dio _dio;
  final Future<String?> Function() _tokenProvider;

  String get baseUrl => _dio.options.baseUrl;

  Future<T> get<T>(
    String path,
    T Function(Map<String, dynamic> json) parser,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(path);
    return _parseEnvelope(response.data, parser);
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    T Function(Map<String, dynamic> json)? parser,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(path, data: data);
    if (parser == null) {
      final body = response.data;
      if (body == null) {
        throw ApiException('Empty response received from server');
      }
      final success = body['success'] == true;
      if (!success) {
        throw ApiException(_extractMessage(body));
      }
      return body as T;
    }
    return _parseEnvelope(response.data, parser);
  }

  Future<void> putBytes(
    String url, {
    required List<int> bytes,
    required Map<String, String> headers,
  }) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );
    await dio.put<void>(url, data: bytes, options: Options(headers: headers));
  }

  Future<T> postMultipart<T>(
    String path, {
    required FormData formData,
    required T Function(Map<String, dynamic> json) parser,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _parseEnvelope(response.data, parser);
  }

  T _parseEnvelope<T>(
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic> json) parser,
  ) {
    if (body == null) {
      throw ApiException('Empty response received from server');
    }
    final success = body['success'] == true;
    if (!success) {
      throw ApiException(_extractMessage(body));
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Response data is missing or invalid');
    }
    return parser(data);
  }

  DioException _mapException(DioException exception) {
    final response = exception.response;
    if (response?.data is Map<String, dynamic>) {
      return DioException(
        requestOptions: exception.requestOptions,
        response: response,
        type: exception.type,
        error: ApiException(
          _extractMessage(response!.data as Map<String, dynamic>),
          statusCode: response.statusCode,
        ),
      );
    }

    return DioException(
      requestOptions: exception.requestOptions,
      response: response,
      type: exception.type,
      error: ApiException(
        exception.message ?? 'Network request failed',
        statusCode: response?.statusCode,
      ),
    );
  }

  String _extractMessage(Map<String, dynamic> body) {
    final message = body['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }
    final detail = body['detail'];
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }
    if (detail is List && detail.isNotEmpty) {
      return detail.first.toString();
    }
    return 'Unexpected server response';
  }
}
