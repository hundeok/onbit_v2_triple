import 'package:dartz/dartz.dart';
import 'package:onbit_v2_triple/core/error/failure.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:onbit_v2_triple/domain/repositories/trade_repository.dart';

class SubscribeLiveTrades {
  final TradeRepository repository;

  SubscribeLiveTrades(this.repository);

  Stream<Either<Failure, Trade>> call(List<String> markets) {
    return repository.subscribeLiveTrades(markets);
  }
}