import 'package:dio/dio.dart';
import 'dart:developer' as dev;

class ErrorHandler {
  static String getErrorMessage(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return "Connection timed out. Please check your internet.";
        case DioExceptionType.sendTimeout:
          return "Request took too long to send.";
        case DioExceptionType.receiveTimeout:
          return "Server took too long to respond.";
        case DioExceptionType.badResponse:
          return _parseServerError(error);
        case DioExceptionType.cancel:
          return "Request was cancelled.";
        case DioExceptionType.connectionError:
          return "Network error. Please check your connection.";
        default:
          return "Unexpected error occurred.";
      }
    } else {
      dev.log(name: "ErrorHandler", error.toString());
      return "Something went wrong. Please try again.";
    }
  }

  static String _parseServerError(DioException error) {
    try {
      final data = error.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
    } catch (_) {}
    return "Server responded with an error.";
  }
}
