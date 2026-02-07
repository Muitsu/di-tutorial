import 'dart:math';
import 'dart:async';
import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int retries;
  final Duration baseDelay;

  RetryInterceptor({
    required this.dio,
    this.retries = 3,
    this.baseDelay = const Duration(seconds: 1),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    var attempt = err.requestOptions.extra['retry_attempt'] ?? 0;

    // Only retry for network errors or timeouts
    if (_shouldRetry(err) && attempt < retries) {
      attempt++;
      final delay = _exponentialBackoff(attempt);
      await Future.delayed(delay);

      // Retry request
      final newOptions = err.requestOptions..extra['retry_attempt'] = attempt;
      try {
        final response = await dio.fetch(newOptions);
        return handler.resolve(response);
      } catch (e) {
        return handler.next(e as DioException);
      }
    }
    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;
  }

  Duration _exponentialBackoff(int attempt) {
    final jitter = Random().nextInt(300); // Random jitter to avoid collision
    return Duration(
      milliseconds: baseDelay.inMilliseconds * pow(2, attempt).toInt() + jitter,
    );
  }
}
