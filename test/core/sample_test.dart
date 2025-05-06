import 'package:flutter_test/flutter_test.dart';
import 'package:onbit_v2_triple/core/sample.dart';

void main() {
  group('Sample', () {
    test('add should return correct sum', () {
      final sample = Sample();
      expect(sample.add(2, 3), 5);
    });

    test('subtract should return correct result', () {
      final sample = Sample();
      expect(sample.subtract(5, 3), 2);
    });
  });
}
