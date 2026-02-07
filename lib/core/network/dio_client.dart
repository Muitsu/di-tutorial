import 'dart:async';
import 'package:dio/dio.dart';
import 'utils/auth_interceptor.dart';
import 'utils/dio_formdata_mixin.dart';
import 'utils/retry_interceptor.dart';

class DioClient with DioFormdataMixin {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  late Dio _dio;

  String? accessToken; // <--- Add this
  String? refreshToken; // <--- Optional
  // A map of request cancel tokens (for canceling specific API calls)
  final Map<String, CancelToken> _cancelTokens = {};

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        followRedirects: true,

        // maxRedirects: 5,
        // validateStatus: (status) {
        //   return status != null && status < 500; // allow redirect codes
        // },
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Attach interceptors
    _dio.interceptors.addAll([
      AuthInterceptor(this),
      LogInterceptor(
        request: true,
        requestBody: true,
        requestHeader: true,
        responseBody: true,
        responseHeader: false,
      ),
      RetryInterceptor(dio: _dio, retries: 0),
    ]);
  }

  Dio get dio => _dio;

  void changeBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;
  }

  CancelToken createCancelToken(String id) {
    final token = CancelToken();
    _cancelTokens[id] = token;
    return token;
  }

  void cancelRequest(String id) {
    if (_cancelTokens.containsKey(id)) {
      _cancelTokens[id]!.cancel("Request cancelled");
      _cancelTokens.remove(id);
    }
  }

  void setAccessToken(String token) {
    accessToken = token;
  }

  void clearAccessToken() {
    accessToken = null;
  }

  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool requireToken = true,
    String? baseUrl,
    String? requestId,
    Map<String, dynamic>? headers,
  }) {
    final cancelToken = requestId != null ? createCancelToken(requestId) : null;
    return _dio.get(
      endpoint,
      queryParameters: queryParameters,
      options: AuthInterceptor.headerOverride(
        requireToken: requireToken,
        customBaseUrl: baseUrl,
        headers: headers,
      ),
      cancelToken: cancelToken,
    );
  }

  Future<Response> post(
    String endpoint, {
    dynamic body,
    String? requestId,
    bool requireToken = true,
    bool isFormData = false,
    Map<String, dynamic>? queryParameters,
    String? baseUrl,
    Map<String, dynamic>? headers,
  }) async {
    final cancelToken = requestId != null ? createCancelToken(requestId) : null;
    final data = body is FormData
        ? body
        : (isFormData ? await createFormData(body) : body);
    return _dio.post(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: AuthInterceptor.headerOverride(
        requireToken: requireToken,
        customBaseUrl: baseUrl,
        headers: headers,
      ),
    );
  }

  /// PUT
  Future<Response> put(
    String endpoint, {
    dynamic body,
    String? requestId,
    bool requireToken = true,
    bool isFormData = false,
    String? baseUrl,
    Map<String, dynamic>? headers,
  }) async {
    final cancelToken = requestId != null ? createCancelToken(requestId) : null;
    final data = body is FormData
        ? body
        : (isFormData ? await createFormData(body) : body);
    return await _dio.put(
      endpoint,
      data: data,
      cancelToken: cancelToken,
      options: AuthInterceptor.headerOverride(
        requireToken: requireToken,
        customBaseUrl: baseUrl,
        headers: headers,
      ),
    );
  }

  /// DELETE
  Future<Response> delete(
    String endpoint, {
    dynamic body,
    String? requestId,
    bool requireToken = true,
    bool isFormData = false,
    String? baseUrl,
    Map<String, dynamic>? headers,
  }) async {
    final cancelToken = requestId != null ? createCancelToken(requestId) : null;
    final data = body is FormData
        ? body
        : (isFormData ? await createFormData(body) : body);
    return await _dio.delete(
      endpoint,
      data: data,
      cancelToken: cancelToken,
      options: AuthInterceptor.headerOverride(
        requireToken: requireToken,
        customBaseUrl: baseUrl,
      ),
    );
  }
}
