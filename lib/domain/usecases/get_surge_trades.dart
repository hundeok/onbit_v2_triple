// lib/domain/usecases/get_surge_trades.dart
import 'package:dartz/dartz.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/error/failure.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:onbit_v2_triple/domain/repositories/trade_repository.dart';

class GetSurgeTrades {
  final TradeRepository repository;
  final AppLogger logger;

  const GetSurgeTrades({
    required this.repository,
    required this.logger,
  });

  Future<Either<Failure, List<Trade>>> call({
    required String symbol,
    double? surgeThreshold,
    Duration? timeWindow = const Duration(minutes: 1),
  }) async {
    try {
      final effectiveThreshold = surgeThreshold ?? AppConfig.surgeThreshold;

      final result = await repository.getFilteredTrades(symbol: symbol);

      return result.fold(
        (failure) {
          logger.logError('GetSurgeTrades failed: ${failure.message}');
          return Left(failure);
        },
        (trades) {
          if (trades.isEmpty) {
            logger.logInfo('GetSurgeTrades: 0 trades for $symbol');
            return const Right(<Trade>[]);
          }

          final filteredTrades = <Trade>[];
          final prices = trades.map((t) => t.price).toList();
          if (prices.length < 2) return Right(filteredTrades);

          final earliestPrice = prices.first;
          for (var trade in trades) {
            final changePercent = ((trade.price - earliestPrice) / earliestPrice) * 100;
            if (changePercent.abs() >= effectiveThreshold) {
              filteredTrades.add(trade);
            }
          }

          logger.logInfo('GetSurgeTrades: ${filteredTrades.length} trades for $symbol');
          return Right(filteredTrades);
        },
      );
    } catch (e, stack) {
      logger.logError('GetSurgeTrades exception', error: e, stackTrace: stack);
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }
}