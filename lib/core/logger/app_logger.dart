import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger();

  void logInfo(String message) => _logger.i(message);
  void logError(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}