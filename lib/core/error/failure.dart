import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final Object? error;

  const Failure({required this.message, this.error});

  @override
  List<Object?> get props => [message, error];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.error});
}

class SocketFailure extends Failure {
  const SocketFailure({required super.message, super.error});
}