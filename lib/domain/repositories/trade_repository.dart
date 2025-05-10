import 'package:dartz/dartz.dart';
import 'package:onbit_v2_triple/core/error/failure.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';

abstract class TradeRepository {
  Stream<Either<Failure, Trade>> subscribeLiveTrades(List<String> markets);
}