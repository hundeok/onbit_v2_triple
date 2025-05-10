class SocketException implements Exception {
  final String message;
  final dynamic error;
  SocketException({required this.message, this.error});

  @override
  String toString() => 'SocketException: $message, error: $error';
}

class DataParsingException implements Exception {
  final String message;
  final dynamic error;
  DataParsingException({required this.message, this.error});

  @override
  String toString() => 'DataParsingException: $message, error: $error';
}

/// REST용 공통 예외 계층
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException({required this.message, this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ServerException extends ApiException {
  const ServerException({required super.message, super.statusCode});
}

class AuthException extends ApiException {
  const AuthException({required super.message, super.statusCode});
}

class NotFoundException extends ApiException {
  const NotFoundException({required super.message, super.statusCode});
}

class NetworkException extends ApiException {
  const NetworkException({required super.message});
}
