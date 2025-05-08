// lib/domain/usecases/get_volume_data.dart
import 'package:dartz/dartz.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/error/failure.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/domain/repositories/trade_repository.dart';

class GetVolumeData {
  final TradeRepository repository;
  final AppLogger logger;

  const GetVolumeData({
    required this.repository,
    required this.logger,
  });

  Future<Either<Failure, Map<String, double>>> call({
    required String symbol,
    int? timeFrame,
  }) async {
    try {
      final effectiveTimeFrame = timeFrame ?? AppConfig.timeFrames[0];

      final result = await repository.getFilteredTrades(symbol: symbol);

      return result.fold(
        (failure) {
          logger.logError('GetVolumeData failed: ${failure.message}');
          return Left(failure);
        },
        (trades) {
          if (trades.isEmpty) {
            logger.logInfo('GetVolumeData: 0 trades for $symbol');
            return const Right(<String, double>{});
          }

          final volumeData = <String, double>{};
          final now = DateTime.now();
          final cutoff = now.subtract(Duration(minutes: effectiveTimeFrame));

          for (var trade in trades) {
            final tradeTime = DateTime.fromMillisecondsSinceEpoch(trade.timestamp);
            if (tradeTime.isAfter(cutoff)) {
              volumeData.update(
                symbol,
                (value) => value + (trade.price * trade.volume),
                ifAbsent: () => trade.price * trade.volume,
              );
            }
          }

          logger.logInfo('GetVolumeData: ${volumeData[symbol] ?? 0} volume for $symbol');
          return Right(volumeData);
        },
      );
    } catch (e, stack) {
      logger.logError('GetVolumeData exception', error: e, stackTrace: stack);
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }
}