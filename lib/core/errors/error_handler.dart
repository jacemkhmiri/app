import 'package:flutter/foundation.dart';
import 'exceptions.dart';
import 'failures.dart';

class ErrorHandler {
  static Failure handleException(Exception exception) {
    if (exception is ServerException) {
      return ServerFailure(
        message: exception.message,
        code: exception.code,
      );
    } else if (exception is NetworkException) {
      return NetworkFailure(
        message: exception.message,
        code: exception.code,
      );
    } else if (exception is CacheException) {
      return CacheFailure(
        message: exception.message,
        code: exception.code,
      );
    } else if (exception is P2PException) {
      return P2PFailure(
        message: exception.message,
        code: exception.code,
      );
    } else if (exception is ValidationException) {
      return ValidationFailure(
        message: exception.message,
        code: exception.code,
      );
    } else if (exception is AuthenticationException) {
      return AuthenticationFailure(
        message: exception.message,
        code: exception.code,
      );
    } else {
      return const ServerFailure(
        message: 'An unexpected error occurred',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  static String getErrorMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error: ${failure.message}';
      case NetworkFailure:
        return 'Network error: ${failure.message}';
      case CacheFailure:
        return 'Storage error: ${failure.message}';
      case P2PFailure:
        return 'Connection error: ${failure.message}';
      case ValidationFailure:
        return 'Validation error: ${failure.message}';
      case AuthenticationFailure:
        return 'Authentication error: ${failure.message}';
      default:
        return 'An unexpected error occurred';
    }
  }

  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('Error in $context: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }
}
