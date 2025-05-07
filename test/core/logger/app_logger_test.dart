import 'package:flutter_test/flutter_test.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';

void main() {
  test('logger should not throw', () {
    expect(() => AppLogger().logInfo('Test log'), returnsNormally);
  });
}
