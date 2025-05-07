import 'package:dartz/dartz.dart';
import 'package:onbit_v2_triple/core/error/failure.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:onbit_v2_triple/domain/repositories/trade_repository.dart';

class GetFilteredTrades {
  final TradeRepository repository;
  final AppLogger logger;

  const GetFilteredTrades({
    required this.repository,
    required this.logger,
  });

  Future<Either<Failure, List<Trade>>> call({
    required String symbol,
    double? minPrice,
    double? maxPrice,
    double? minVolume,
    double? minTotal, // CoinDetector의 total 필터링 참고
  }) async {
    try {
      final result = await repository.getFilteredTrades(
        symbol: symbol,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minVolume: minVolume,
      );

      return result.fold(
        (failure) {
          logger.logError('GetFilteredTrades failed: ${failure.message}');
          return Left(failure);
        },
        (trades) {
          if (trades.isEmpty) {
            logger.logInfo('GetFilteredTrades: 0 trades for $symbol');
            return const Right(<Trade>[]);
          }

          // CoinDetector처럼 total (price * volume) 필터링 추가
          final filteredTrades = trades.where((trade) {
            final total = trade.price * trade.volume;
            return minTotal == null || total >= minTotal;
          }).toList();
          
          logger.logInfo('GetFilteredTrades: ${filteredTrades.length} trades for $symbol');
          return Right(filteredTrades);
        },
      );
    } catch (e, stack) {
      logger.logError('GetFilteredTrades exception', error: e, stackTrace: stack);
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }
}