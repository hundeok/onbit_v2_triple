import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:onbit_v2_triple/core/error/failure.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:onbit_v2_triple/domain/repositories/trade_repository.dart';
import 'package:onbit_v2_triple/domain/usecases/get_filtered_trades.dart';
import 'get_filtered_trades_test.mocks.dart';

@GenerateMocks([TradeRepository, AppLogger])
void main() {
  late GetFilteredTrades useCase;
  late MockTradeRepository mockRepository;
  late MockAppLogger mockLogger;
  
  setUp(() {
    mockRepository = MockTradeRepository();
    mockLogger = MockAppLogger();
    useCase = GetFilteredTrades(
      repository: mockRepository,
      logger: mockLogger,
    );
  });
  
  const tSymbol = 'KRW-BTC';
  const tTrades = [
    Trade(
      symbol: tSymbol,
      price: 50000.0,
      volume: 1.0,
      timestamp: 123456,
      isBuy: true,
      sequentialId: '1',
    ),
  ];
  
  test('should return filtered trades from repository', () async {
    // Arrange
    when(mockRepository.getFilteredTrades(
      symbol: tSymbol,
      minPrice: anyNamed('minPrice'),
      maxPrice: anyNamed('maxPrice'),
      minVolume: anyNamed('minVolume'),
    )).thenAnswer((_) async => const Right(tTrades));  // const 추가
    
    // Act
    final result = await useCase(
      symbol: tSymbol,
      minPrice: 40000.0,
      maxPrice: 60000.0,
      minVolume: 0.5,
      minTotal: 40000.0,
    );
    
    // Assert
    expect(result, const Right(tTrades));  // const 추가
    verify(mockLogger.logInfo('GetFilteredTrades: ${tTrades.length} trades for $tSymbol'));
    verifyNoMoreInteractions(mockLogger);
  });
  
  test('should return failure when repository fails', () async {
    // Arrange
    const tFailure = ServerFailure(message: 'Test failure');  // const 추가
    when(mockRepository.getFilteredTrades(
      symbol: tSymbol,
      minPrice: anyNamed('minPrice'),
      maxPrice: anyNamed('maxPrice'),
      minVolume: anyNamed('minVolume'),
    )).thenAnswer((_) async => const Left(tFailure));  // const 추가
    
    // Act
    final result = await useCase(symbol: tSymbol);
    
    // Assert
    expect(result, const Left(tFailure));  // const 추가
    verify(mockLogger.logError('GetFilteredTrades failed: ${tFailure.message}'));
    verifyNoMoreInteractions(mockLogger);
  });
}