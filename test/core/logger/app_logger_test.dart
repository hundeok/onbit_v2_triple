import 'package:flutter_test/flutter_test.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';

void main() {
  group('AppLogger', () {
    final logger = AppLogger();

    test('logInfo should not throw', () {
      expect(() => logger.logInfo('Test Info'), returnsNormally);
    });

    test('logWarning should not throw', () {
      expect(() => logger.logWarning('Test Warning'), returnsNormally);
    });

    test('logError should not throw', () {
      expect(() => logger.logError('Test Error'), returnsNormally);
    });
  });
}
