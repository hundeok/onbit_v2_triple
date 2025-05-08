import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/domain/usecases/get_volume_data.dart';
import 'package:onbit_v2_triple/presentation/controllers/volume_controller.dart';
import 'package:onbit_v2_triple/presentation/pages/volume/volume_view.dart';
import 'volume_view_test.mocks.dart';

@GenerateMocks([GetVolumeData, AppLogger])
void main() {
  late MockGetVolumeData mockGetVolumeData;
  late MockAppLogger mockLogger;
  late VolumeController controller;
  
  setUp(() {
    Get.testMode = true;
    mockGetVolumeData = MockGetVolumeData();
    mockLogger = MockAppLogger();
    controller = VolumeController(
      getVolumeData: mockGetVolumeData,
      logger: mockLogger,
    );
    Get.put<VolumeController>(controller, tag: 'controller.volume');
  });
  
  tearDown(() {
    Get.reset();
  });
  
  const tSymbol = 'KRW-BTC'; // 유지하고 활용
  final Map<String, double> tVolumeData = {tSymbol: 50000.0}; // tSymbol 활용
  
  testWidgets('should display volume data from controller', (WidgetTester tester) async {
    // Arrange
    controller.volumeData.assignAll(tVolumeData);
    await tester.pumpWidget(
      const MaterialApp(
        home: VolumeView(),
      ),
    );
    
    // Act
    await tester.pump();
    
    // Assert
    expect(find.text(tSymbol), findsOneWidget); // tSymbol 활용
    expect(find.textContaining('거래량: ₩50,000'), findsOneWidget);
  });
  
  testWidgets('should show loading indicator when isLoading is true', (WidgetTester tester) async {
    // Arrange
    controller.isLoading.value = true;
    await tester.pumpWidget(
      const MaterialApp(
        home: VolumeView(),
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
        home: VolumeView(),
      ),
    );
    
    // Act
    await tester.pump();
    
    // Assert
    expect(find.text('Test error'), findsOneWidget);
  });
  
  testWidgets('should show no volume data message when volumeData is empty', (WidgetTester tester) async {
    // Arrange
    controller.volumeData.clear();
    await tester.pumpWidget(
      const MaterialApp(
        home: VolumeView(),
      ),
    );
    
    // Act
    await tester.pump();
    
    // Assert
    expect(find.text('No volume data available'), findsOneWidget);
  });
}