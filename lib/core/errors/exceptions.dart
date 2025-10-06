class ServerException implements Exception {
  final String message;
  final String? code;

  const ServerException({
    required this.message,
    this.code,
  });
}

class NetworkException implements Exception {
  final String message;
  final String? code;

  const NetworkException({
    required this.message,
    this.code,
  });
}

class CacheException implements Exception {
  final String message;
  final String? code;

  const CacheException({
    required this.message,
    this.code,
  });
}

class P2PException implements Exception {
  final String message;
  final String? code;

  const P2PException({
    required this.message,
    this.code,
  });
}

class ValidationException implements Exception {
  final String message;
  final String? code;

  const ValidationException({
    required this.message,
    this.code,
  });
}

class AuthenticationException implements Exception {
  final String message;
  final String? code;

  const AuthenticationException({
    required this.message,
    this.code,
  });
}
