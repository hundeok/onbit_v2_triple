// lib/domain/usecases/get_momentary_trades.dart
import 'package:dartz/dartz.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/error/failure.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:onbit_v2_triple/domain/repositories/trade_repository.dart';

class GetMomentaryTrades {
  final TradeRepository repository;
  final AppLogger logger;

  const GetMomentaryTrades({
    required this.repository,
    required this.logger,
  });

  Future<Either<Failure, List<Trade>>> call({
    required String symbol,
    double? minAmount,
    double? threshold,
  }) async {
    try {
      final effectiveMinAmount = minAmount ?? AppConfig.momentaryMinAmount;
      final effectiveThreshold = threshold ?? AppConfig.momentaryThreshold;

      final result = await repository.getFilteredTrades(
        symbol: symbol,
        minVolume: effectiveMinAmount / 50000.0,
      );

      return result.fold(
        (failure) {
          logger.logError('GetMomentaryTrades failed: ${failure.message}');
          return Left(failure);
        },
        (trades) {
          if (trades.isEmpty) {
            logger.logInfo('GetMomentaryTrades: 0 trades for $symbol');
            return const Right(<Trade>[]);
          }

          final filteredTrades = trades.where((trade) {
            final amount = trade.price * trade.volume;
            return amount >= effectiveThreshold;
          }).toList();

          logger.logInfo('GetMomentaryTrades: ${filteredTrades.length} trades for $symbol');
          return Right(filteredTrades);
        },
      );
    } catch (e, stack) {
      logger.logError('GetMomentaryTrades exception', error: e, stackTrace: stack);
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }
}