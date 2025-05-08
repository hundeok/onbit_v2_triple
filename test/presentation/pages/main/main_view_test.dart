import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/domain/usecases/get_filtered_trades.dart';
import 'package:onbit_v2_triple/domain/usecases/get_momentary_trades.dart';
import 'package:onbit_v2_triple/domain/usecases/get_surge_trades.dart';
import 'package:onbit_v2_triple/domain/usecases/get_volume_data.dart';
import 'package:onbit_v2_triple/presentation/controllers/main_controller.dart';
import 'package:onbit_v2_triple/presentation/controllers/momentary_controller.dart';
import 'package:onbit_v2_triple/presentation/controllers/surge_controller.dart';
import 'package:onbit_v2_triple/presentation/controllers/trade_controller.dart';
import 'package:onbit_v2_triple/presentation/controllers/volume_controller.dart';
import 'package:onbit_v2_triple/presentation/pages/main/main_view.dart';
import 'package:onbit_v2_triple/presentation/pages/trade/trade_view.dart';

// Mock 클래스들 정의
class MockAppLogger extends Mock implements AppLogger {}
class MockGetFilteredTrades extends Mock implements GetFilteredTrades {}
class MockGetMomentaryTrades extends Mock implements GetMomentaryTrades {}
class MockGetSurgeTrades extends Mock implements GetSurgeTrades {}
class MockGetVolumeData extends Mock implements GetVolumeData {}

void main() {
  late MockAppLogger mockLogger;
  late MockGetFilteredTrades mockGetFilteredTrades;
  late MockGetMomentaryTrades mockGetMomentaryTrades;
  late MockGetSurgeTrades mockGetSurgeTrades;
  late MockGetVolumeData mockGetVolumeData;
  
  setUp(() {
    Get.testMode = true;
    mockLogger = MockAppLogger();
    mockGetFilteredTrades = MockGetFilteredTrades();
    mockGetMomentaryTrades = MockGetMomentaryTrades();
    mockGetSurgeTrades = MockGetSurgeTrades();
    mockGetVolumeData = MockGetVolumeData();
    
    // 먼저 모든 컨트롤러 등록
    Get.put<TradeController>(
      TradeController(
        getFilteredTrades: mockGetFilteredTrades,
        logger: mockLogger,
      ),
      tag: 'controller.trade',
    );
    
    Get.put<MomentaryController>(
      MomentaryController(
        getMomentaryTrades: mockGetMomentaryTrades,
        logger: mockLogger,
      ),
      tag: 'controller.momentary',
    );
    
    Get.put<SurgeController>(
      SurgeController(
        getSurgeTrades: mockGetSurgeTrades,
        logger: mockLogger,
      ),
      tag: 'controller.surge',
    );
    
    Get.put<VolumeController>(
      VolumeController(
        getVolumeData: mockGetVolumeData,
        logger: mockLogger,
      ),
      tag: 'controller.volume',
    );
    
    // 마지막으로 MainController 등록
    Get.put<MainController>(
      MainController(logger: mockLogger),
      tag: 'controller.main',
    );
  });
  
  tearDown(() {
    Get.reset();
  });
  
  testWidgets('should display TradeView by default', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      const MaterialApp(
        home: MainView(),
      ),
    );
    
    // Act
    await tester.pump();
    
    // Assert
    expect(find.byType(TradeView), findsOneWidget);
    expect(find.text('Trade View'), findsOneWidget);
  });
  
  testWidgets('should switch to MomentaryView when tapped', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      const MaterialApp(
        home: MainView(),
      ),
    );
    
    // Act
    await tester.tap(find.text('Momentary'));
    await tester.pump();
    
    // Assert
    expect(find.text('Momentary Trades'), findsOneWidget);
  });
  
  testWidgets('should switch to SurgeView when tapped', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      const MaterialApp(
        home: MainView(),
      ),
    );
    
    // Act
    await tester.tap(find.text('Surge'));
    await tester.pump();
    
    // Assert
    expect(find.text('Surge Trades'), findsOneWidget);
  });
  
  testWidgets('should switch to VolumeView when tapped', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      const MaterialApp(
        home: MainView(),
      ),
    );
    
    // Act
    await tester.tap(find.text('Volume'));
    await tester.pump();
    
    // Assert
    expect(find.text('Volume Data'), findsOneWidget);
  });
}