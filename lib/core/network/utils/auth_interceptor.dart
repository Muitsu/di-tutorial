import 'dart:async';
import 'package:dio/dio.dart';
import '../dio_client.dart';

class AuthInterceptor extends Interceptor {
  final DioClient dioClient;
  bool _isRefreshing = false;
  final List<QueuedRequest> _queue = [];

  AuthInterceptor(this.dioClient);

  // ignore: prefer_final_fields
  String? _refreshToken = "refresh_token";
  static Options headerOverride({
    required bool requireToken,
    String? customBaseUrl,
    Map<String, dynamic>? headers,
  }) {
    return Options(
      extra: {
        "requiresAuth": requireToken,
        "baseUrl": customBaseUrl,
        "customHeaders": headers,
      },
    );
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requiresAuth = options.extra["requiresAuth"] ?? true;

    //Auth Options
    if (requiresAuth && dioClient.accessToken != null) {
      options.headers['Authorization'] = 'Bearer ${dioClient.accessToken}';
    }
    // Read custom headers
    final customHeaders =
        options.extra["customHeaders"] as Map<String, dynamic>?;
    if (customHeaders != null) {
      customHeaders.remove("Authorization");
      options.headers.addAll(customHeaders);
    }
    //Base Url Options
    String? customUrl = options.extra["baseUrl"];
    options.baseUrl = customUrl ?? dioClient.dio.options.baseUrl;
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If token expired
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final newToken = await _refreshAccessToken();
        dioClient.setAccessToken(newToken);
        _isRefreshing = false;

        // Retry all queued requests
        for (final req in _queue) {
          req.requestOptions.headers['Authorization'] =
              'Bearer ${dioClient.accessToken}';
          final response = await dioClient.dio.fetch(req.requestOptions);
          req.completer.complete(response);
        }
        _queue.clear();
      } catch (e) {
        _isRefreshing = false;
        for (final req in _queue) {
          req.completer.completeError(e);
        }
        _queue.clear();
      }

      return handler.resolve(await dioClient.dio.fetch(err.requestOptions));
    } else if (_isRefreshing) {
      final completer = Completer<Response>();
      _queue.add(QueuedRequest(err.requestOptions, completer));
      return completer.future
          .then((r) => handler.resolve(r))
          .catchError((e) => handler.reject(e));
    }

    return handler.next(err);
  }

  Future<String> _refreshAccessToken() async {
    final response = await dioClient.dio.post(
      '/auth/refresh',
      data: {'refresh_token': _refreshToken},
    );
    return response.data['access_token'];
  }
}

class QueuedRequest {
  final RequestOptions requestOptions;
  final Completer<Response> completer;
  QueuedRequest(this.requestOptions, this.completer);
}
