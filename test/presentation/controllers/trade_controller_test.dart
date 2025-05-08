import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:onbit_v2_triple/core/error/failure.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:onbit_v2_triple/domain/usecases/get_filtered_trades.dart';
import 'package:onbit_v2_triple/presentation/controllers/trade_controller.dart';
import 'trade_controller_test.mocks.dart';

@GenerateMocks([GetFilteredTrades, AppLogger])
void main() {
  late TradeController controller;
  late MockGetFilteredTrades mockGetFilteredTrades;
  late MockAppLogger mockLogger;
  
  setUp(() {
    mockGetFilteredTrades = MockGetFilteredTrades();
    mockLogger = MockAppLogger();
    controller = TradeController(
      getFilteredTrades: mockGetFilteredTrades,
      logger: mockLogger,
    );
    Get.reset();
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
  
  test('should fetch and update trades on success', () async {
    // Arrange
    when(mockGetFilteredTrades(
      symbol: tSymbol,
      minPrice: anyNamed('minPrice'),
      maxPrice: anyNamed('maxPrice'),
      minVolume: anyNamed('minVolume'),
      minTotal: anyNamed('minTotal'),
    )).thenAnswer((_) async => const Right(tTrades));  // const 추가
    
    // Act
    await controller.fetchFilteredTrades(
      symbol: tSymbol,
      minPrice: 40000.0,
      maxPrice: 60000.0,
      minVolume: 0.5,
      minTotal: 40000.0,
    );
    
    // Assert
    expect(controller.trades, tTrades);
    expect(controller.isLoading.value, false);
    expect(controller.errorMessage.value, '');
    verify(mockLogger.logInfo('Fetched ${tTrades.length} trades for $tSymbol'));
    verifyNoMoreInteractions(mockLogger);
  });
  
  test('should handle failure and update error message', () async {
    // Arrange
    const tFailure = ServerFailure(message: 'Test failure');
    when(mockGetFilteredTrades(
      symbol: tSymbol,
      minPrice: anyNamed('minPrice'),
      maxPrice: anyNamed('maxPrice'),
      minVolume: anyNamed('minVolume'),
      minTotal: anyNamed('minTotal'),
    )).thenAnswer((_) async => const Left(tFailure));  // const 추가
    
    // Act
    await controller.fetchFilteredTrades(symbol: tSymbol);
    
    // Assert
    expect(controller.trades, []);
    expect(controller.isLoading.value, false);
    expect(controller.errorMessage.value, tFailure.getUIMessage());
    verify(mockLogger.logError('Fetch trades failed: ${tFailure.message}'));
    verifyNoMoreInteractions(mockLogger);
  });
}