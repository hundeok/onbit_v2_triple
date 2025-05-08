// lib/core/config/app_config.dart

// 명시적으로 ExchangePlatform enum 추가
enum ExchangePlatform {
  upbit,
  binance,
  bybit,
  bithumb,
}

class AppConfig {
  static const List<double> tradeFilters = [
    2000000.0,
    5000000.0,
    10000000.0,
    20000000.0,
    50000000.0,
    100000000.0,
    200000000.0,
    300000000.0,
    400000000.0,
    500000000.0,
    1000000000.0,
  ];

  static final Map<double, String> filterNames = {
    2000000.0: '2백만',
    5000000.0: '5백만',
    10000000.0: '1천만',
    20000000.0: '2천만',
    50000000.0: '5천만',
    100000000.0: '1억',
    200000000.0: '2억',
    300000000.0: '3억',
    400000000.0: '4억',
    500000000.0: '5억',
    1000000000.0: '10억',
  };

  static const List<int> timeFrames = [
    1, 5, 15, 30, 60, 120, 240, 480, 720, 1440,
  ];

  static const Map<int, String> timeFrameNames = {
    1: '1분',
    5: '5분',
    15: '15분',
    30: '30분',
    60: '1시간',
    120: '2시간',
    240: '4시간',
    480: '8시간',
    720: '12시간',
    1440: '1일',
  };

  static const int mergeWindowMs = 1000;
  static const ExchangePlatform defaultPlatform = ExchangePlatform.upbit;

  static const double momentaryMinAmount = 500000.0;
  static const double momentaryThreshold = 2000000.0;
  static const double surgeThreshold = 1.1;
}