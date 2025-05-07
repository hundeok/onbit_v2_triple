import 'package:equatable/equatable.dart';

/// 앱에서 발생 가능한 실패 상태를 정의합니다.
abstract class Failure extends Equatable {
  final String message;
  final Object? error;

  const Failure({
    required this.message,
    this.error,
  });

  /// UI에 표시할 메시지를 생성합니다.
  String getUIMessage();

  @override
  List<Object?> get props => [message, error];
}

/// 서버 관련 실패
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.error,
  });

  @override
  String getUIMessage() => '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
}

/// 네트워크 실패
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.error,
  });

  @override
  String getUIMessage() => '네트워크 연결을 확인해주세요.';
}

/// 소켓 연결 실패
class SocketFailure extends Failure {
  const SocketFailure({
    required super.message,
    super.error,
  });

  @override
  String getUIMessage() => '실시간 데이터 연결에 실패했습니다. 잠시 후 다시 시도합니다.';
}

/// 캐시 실패
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.error,
  });

  @override
  String getUIMessage() => '데이터 저장에 실패했습니다.';
}

/// 입력값 유효성 검증 실패
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.error,
  });

  @override
  String getUIMessage() => message;
}