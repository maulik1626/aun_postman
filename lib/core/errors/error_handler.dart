import 'dart:io';

import 'package:aun_postman/core/errors/app_exception.dart';
import 'package:dio/dio.dart';

class ErrorHandler {
  static AppException handle(Object error) {
    if (error is AppException) return error;

    if (error is DioException) {
      return _handleDio(error);
    }

    if (error is SocketException) {
      return NetworkException('No internet connection: ${error.message}');
    }

    if (error is HttpException) {
      return NetworkException(error.message);
    }

    if (error is FormatException) {
      return ParseException('Invalid response format: ${error.message}');
    }

    return UnknownException(error.toString());
  }

  static AppException _handleDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.cancel:
        return const CancelException();
      case DioExceptionType.connectionError:
        return NetworkException(
          error.message ?? 'Connection failed',
        );
      case DioExceptionType.badResponse:
        return NetworkException(
          'Server error: ${error.response?.statusCode}',
        );
      case DioExceptionType.badCertificate:
        return const NetworkException('SSL certificate error');
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return const NetworkException('No internet connection');
        }
        return UnknownException(error.message ?? 'Unknown error');
    }
  }
}
