import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger();
  
  void logInfo(String message) => _logger.i(message);
  
  void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    // Logger 1.4.0 버전은 error와 stackTrace 파라미터가 없어서 message에 포함
    final errorMsg = error != null ? '$message, Error: $error' : message;
    final stackMsg = stackTrace != null ? '\nStackTrace: $stackTrace' : '';
    _logger.e('$errorMsg$stackMsg');
  }
}