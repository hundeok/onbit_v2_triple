import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:onbit_v2_triple/domain/usecases/get_momentary_trades.dart';
import 'package:onbit_v2_triple/presentation/controllers/momentary_controller.dart';
import 'package:onbit_v2_triple/presentation/pages/momentary/momentary_view.dart';
import 'momentary_view_test.mocks.dart';

@GenerateMocks([GetMomentaryTrades, AppLogger])
void main() {
  late MockGetMomentaryTrades mockGetMomentaryTrades;
  late MockAppLogger mockLogger;
  late MomentaryController controller;

  setUp(() {
    Get.testMode = true;
    mockGetMomentaryTrades = MockGetMomentaryTrades();
    mockLogger = MockAppLogger();
    controller = MomentaryController(
      getMomentaryTrades: mockGetMomentaryTrades,
      logger: mockLogger,
    );
    Get.put<MomentaryController>(controller, tag: 'controller.momentary');
  });

  tearDown(() {
    Get.reset();
  });

  const tTrade = Trade(
    symbol: 'KRW-BTC',
    price: 50000.0,
    volume: 40.0,
    timestamp: 123456,
    isBuy: true,
    sequentialId: '1',
  );

  testWidgets('should display momentary trades from controller', (WidgetTester tester) async {
    // Arrange
    controller.trades.add(tTrade);
    await tester.pumpWidget(
      const MaterialApp(
        home: MomentaryView(),
      ),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('KRW-BTC'), findsOneWidget);
    expect(find.textContaining('가격: ₩50,000'), findsOneWidget);
    expect(find.text('거래량: 40.00'), findsOneWidget);
    expect(find.text('매수'), findsOneWidget);
  });

  testWidgets('should show loading indicator when isLoading is true', (WidgetTester tester) async {
    // Arrange
    controller.isLoading.value = true;
    await tester.pumpWidget(
      const MaterialApp(
        home: MomentaryView(),
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
        home: MomentaryView(),
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
        home: MomentaryView(),
      ),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('No momentary trades available'), findsOneWidget);
  });
}