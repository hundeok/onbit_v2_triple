import 'package:flutter_test/flutter_test.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';

void main() {
  late AppLogger logger;

  setUp(() {
    logger = AppLogger();
  });

  test('should log info message', () {
    expect(() => logger.logInfo('Test info'), returnsNormally);
  });

  test('should log error message', () {
    expect(() => logger.logError('Test error', error: Exception('Test')), returnsNormally);
  });
}