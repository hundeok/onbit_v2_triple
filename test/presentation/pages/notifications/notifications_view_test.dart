import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/presentation/pages/notifications/notifications_view.dart';
import 'notifications_view_test.mocks.dart';

@GenerateMocks([AppLogger])
void main() {
  late MockAppLogger mockLogger;

  setUp(() {
    Get.testMode = true;
    mockLogger = MockAppLogger();
    Get.put<AppLogger>(mockLogger, tag: 'core.logger');
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('should display notifications view with test button', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationsView(),
      ),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Notifications not implemented yet'), findsOneWidget);
    expect(find.text('Test Notification'), findsOneWidget);
  });

  testWidgets('should log and show snackbar when test button is pressed', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationsView(),
      ),
    );

    // Act
    await tester.tap(find.text('Test Notification'));
    await tester.pump();

    // Assert
    verify(mockLogger.logInfo('Test notification triggered')).called(1);
    expect(find.text('Notification'), findsOneWidget);
    expect(find.text('Test notification logged'), findsOneWidget);
  });
}