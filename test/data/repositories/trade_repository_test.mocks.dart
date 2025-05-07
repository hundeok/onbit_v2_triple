// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
import 'package:mockito/mockito.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/data/datasources/socket_trade_source.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';

class MockSocketTradeSource extends Mock implements SocketTradeSource {
  @override
  Stream<Trade> get tradeStream => super.noSuchMethod(
        Invocation.getter(#tradeStream),
        returnValue: Stream<Trade>.empty(),
      ) as Stream<Trade>;
}

class MockAppLogger extends Mock implements AppLogger {}