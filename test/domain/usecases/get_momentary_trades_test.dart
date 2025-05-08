// test/domain/usecases/get_momentary_trades_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:onbit_v2_triple/core/error/failure.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:onbit_v2_triple/domain/repositories/trade_repository.dart';
import 'package:onbit_v2_triple/domain/usecases/get_momentary_trades.dart';

// Mocks 수동 정의 (build_runner로 자동 생성하기 전에)
class MockTradeRepository extends Mock implements TradeRepository {}
class MockAppLogger extends Mock implements AppLogger {}

void main() {
  late GetMomentaryTrades useCase;
  late MockTradeRepository mockRepository;
  late MockAppLogger mockLogger;

  setUp(() {
    mockRepository = MockTradeRepository();
    mockLogger = MockAppLogger();
    useCase = GetMomentaryTrades(
      repository: mockRepository,
      logger: mockLogger,
    );
  });

  const tSymbol = 'KRW-BTC';
  const tTrades = [
    Trade(
      symbol: tSymbol,
      price: 50000.0,
      volume: 40.0,
      timestamp: 123456,
      isBuy: true,
      sequentialId: '1',
    ),
  ];

  test('should return momentary trades from repository', () async {
    // Arrange
    when(mockRepository.getFilteredTrades(
      symbol: tSymbol,
      minVolume: anyNamed('minVolume'),
    )).thenAnswer((_) async => const Right(tTrades));
    // Act
    final result = await useCase(
      symbol: tSymbol,
      minAmount: 500000.0,
      threshold: 2000000.0,
    );
    // Assert
    expect(result, const Right(tTrades));
    verify(mockLogger.logInfo('GetMomentaryTrades: ${tTrades.length} trades for $tSymbol'));
    verifyNoMoreInteractions(mockLogger);
  });

  test('should return failure when repository fails', () async {
    // Arrange
    const tFailure = ServerFailure(message: 'Test failure');
    when(mockRepository.getFilteredTrades(
      symbol: tSymbol,
      minVolume: anyNamed('minVolume'),
    )).thenAnswer((_) async => const Left(tFailure));
    // Act
    final result = await useCase(symbol: tSymbol);
    // Assert
    expect(result, const Left(tFailure));
    verify(mockLogger.logError('GetMomentaryTrades failed: ${tFailure.message}'));
    verifyNoMoreInteractions(mockLogger);
  });
}