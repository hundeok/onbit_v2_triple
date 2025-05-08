import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
// 'package:mockito/mockito.dart' import 제거 (사용하지 않음)
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:onbit_v2_triple/domain/usecases/get_filtered_trades.dart';
import 'package:onbit_v2_triple/presentation/controllers/trade_controller.dart';
import 'package:onbit_v2_triple/presentation/pages/trade/trade_view.dart';
import 'trade_view_test.mocks.dart';

@GenerateMocks([GetFilteredTrades, AppLogger])
void main() {
  late MockGetFilteredTrades mockGetFilteredTrades;
  late MockAppLogger mockLogger;
  late TradeController controller;
  
  setUp(() {
    Get.testMode = true;
    mockGetFilteredTrades = MockGetFilteredTrades();
    mockLogger = MockAppLogger();
    controller = TradeController(
      getFilteredTrades: mockGetFilteredTrades,
      logger: mockLogger,
    );
    Get.put<TradeController>(controller, tag: 'controller.trade');
  });
  
  tearDown(() {
    Get.reset();
  });
  
  // final을 const로 변경
  const tTrade = Trade(
    symbol: 'KRW-BTC',
    price: 50000.0,
    volume: 1.0,
    timestamp: 123456,
    isBuy: true,
    sequentialId: '1',
  );
  
  testWidgets('should display trades from controller', (WidgetTester tester) async {
    // Arrange
    controller.trades.add(tTrade);
    await tester.pumpWidget(
      const MaterialApp(
        home: TradeView(),
      ),
    );
    
    // Act
    await tester.pump();
    
    // Assert
    expect(find.text('KRW-BTC'), findsOneWidget);
    expect(find.textContaining('가격: ₩50,000'), findsOneWidget);
    expect(find.text('거래량: 1.00'), findsOneWidget);
    expect(find.text('매수'), findsOneWidget);
  });
  
  testWidgets('should show loading indicator when isLoading is true', (WidgetTester tester) async {
    // Arrange
    controller.isLoading.value = true;
    await tester.pumpWidget(
      const MaterialApp(
        home: TradeView(),
      ),
    );
    
    // Act
    await tester.pump();
    
    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
  
  testWidgets('should show error message when errorMessage is not empty', (WidgetTester tester) async {
    // Arrange
    controller.errorMessage.value = 'Test error';
    await tester.pumpWidget(
      const MaterialApp(
        home: TradeView(),
      ),
    );
    
    // Act
    await tester.pump();
    
    // Assert
    expect(find.text('Test error'), findsOneWidget);
  });
  
  testWidgets('should show no trades message when trades is empty', (WidgetTester tester) async {
    // Arrange
    controller.trades.clear();
    await tester.pumpWidget(
      const MaterialApp(
        home: TradeView(),
      ),
    );
    
    // Act
    await tester.pump();
    
    // Assert
    expect(find.text('No trades available'), findsOneWidget);
  });
}