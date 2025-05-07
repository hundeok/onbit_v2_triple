import 'package:dartz/dartz.dart';
import 'package:onbit_v2_triple/core/error/failure.dart'; // failures.dart → failure.dart
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/data/datasources/socket_trade_source.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:onbit_v2_triple/domain/repositories/trade_repository.dart';

class TradeRepositoryImpl implements TradeRepository {
  final SocketTradeSource socketTradeSource;
  final AppLogger logger;

  TradeRepositoryImpl({
    required this.socketTradeSource,
    required this.logger,
  });

  @override
  Future<Either<Failure, List<Trade>>> getFilteredTrades({
    required String symbol,
    double? minPrice,
    double? maxPrice,
    double? minVolume,
  }) async {
    try {
      final trades = <Trade>[];
      await for (final trade in socketTradeSource.tradeStream) {
        if (trade.symbol == symbol) {
          if ((minPrice == null || trade.price >= minPrice) &&
              (maxPrice == null || trade.price <= maxPrice) &&
              (minVolume == null || trade.volume >= minVolume)) {
            trades.add(trade);
          }
        }
        if (trades.length >= 100) break;
      }
      logger.logInfo('Filtered ${trades.length} trades for $symbol');
      return Right(trades);
    } catch (e, stack) {
      logger.logError('Failed to fetch filtered trades', error: e, stackTrace: stack);
      return Left(ServerFailure(message: 'Failed to fetch trades: $e'));
    }
  }
}