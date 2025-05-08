import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/presentation/controllers/main_controller.dart';
import 'main_controller_test.mocks.dart';

@GenerateMocks([AppLogger])
void main() {
  late MainController controller;
  late MockAppLogger mockLogger;

  setUp(() {
    Get.testMode = true;
    mockLogger = MockAppLogger();
    controller = MainController(logger: mockLogger);
  });

  tearDown(() {
    Get.reset();
  });

  test('should change page index and log event', () {
    // Arrange
    expect(controller.currentIndex.value, 0);

    // Act
    controller.changePage(1);

    // Assert
    expect(controller.currentIndex.value, 1);
    verify(mockLogger.logInfo('Page changed to index: 1')).called(1);
    verifyNoMoreInteractions(mockLogger);
  });

  test('should not change page index if same index', () {
    // Arrange
    controller.changePage(1);
    expect(controller.currentIndex.value, 1);
    reset(mockLogger);

    // Act
    controller.changePage(1);

    // Assert
    expect(controller.currentIndex.value, 1);
    verifyNever(mockLogger.logInfo(any));
  });
}