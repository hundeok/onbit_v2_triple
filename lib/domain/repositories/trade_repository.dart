import 'package:dartz/dartz.dart';
import 'package:onbit_v2_triple/core/error/failure.dart'; // failures.dart → failure.dart
import 'package:onbit_v2_triple/domain/entities/trade.dart';

abstract class TradeRepository {
  Future<Either<Failure, List<Trade>>> getFilteredTrades({
    required String symbol,
    double? minPrice,
    double? maxPrice,
    double? minVolume,
  });
}