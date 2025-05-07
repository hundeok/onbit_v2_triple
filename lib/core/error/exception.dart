/// 앱에서 발생 가능한 예외 클래스들을 정의합니다.
library onbit_v2_triple.core.error.exception;

/// 서버 관련 예외
class ServerException implements Exception {
  final String message;
  final dynamic error;

  ServerException({
    required this.message,
    this.error,
  });
  
  @override
  String toString() => 'ServerException: $message, error: $error';
}

/// 캐시 관련 예외
class CacheException implements Exception {
  final String message;
  final dynamic error;

  CacheException({
    required this.message,
    this.error,
  });
  
  @override
  String toString() => 'CacheException: $message, error: $error';
}

/// 네트워크 연결 관련 예외
class NetworkException implements Exception {
  final String message;
  final dynamic error;

  NetworkException({
    required this.message,
    this.error,
  });
  
  @override
  String toString() => 'NetworkException: $message, error: $error';
}

/// 소켓 연결 관련 예외
class SocketException implements Exception {
  final String message;
  final dynamic error;

  SocketException({
    required this.message,
    this.error,
  });
  
  @override
  String toString() => 'SocketException: $message, error: $error';
}

/// 데이터 파싱 관련 예외
class DataParsingException implements Exception {
  final String message;
  final dynamic error;

  DataParsingException({
    required this.message,
    this.error,
  });
  
  @override
  String toString() => 'DataParsingException: $message, error: $error';
}