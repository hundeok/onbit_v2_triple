import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/di/tags.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';
import 'package:onbit_v2_triple/data/models/market_model.dart';

/// MarketFormatExtension 관련 SignalBus 이벤트 클래스들
/// 마켓 포맷팅 이벤트
class MarketFormattedEvent extends SignalEvent {
  final String method;
  final String symbol;
  
  MarketFormattedEvent(this.method, this.symbol) 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'market_formatted',
    'method': method,
    'symbol': symbol,
    'sequentialId': sequentialId.toString(),
  };
}

/// 코인 이름 파싱 에러 이벤트
class CoinNameParseErrorEvent extends SignalEvent {
  final String symbol;
  final String platform;
  final String error;
  
  CoinNameParseErrorEvent({
    required this.symbol,
    required this.platform,
    required this.error,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'coin_name_parse_error',
    'symbol': symbol,
    'platform': platform,
    'error': error,
    'sequentialId': sequentialId.toString(),
  };
}

/// [MarketModel]의 포맷팅 확장.
/// - 가격, 변동률, 거래량, 코인 이름 등을 UI에 적합한 형식으로 변환.
/// - [AppConfig]에서 포맷 설정 참조.
/// @see [MarketModel] for data structure.
extension MarketFormatExtension on MarketModel {
  static final _priceFormatter = NumberFormat(AppConfig.priceFormatPattern);
  static final _percentageFormatter = NumberFormat(AppConfig.percentageFormatPattern);
  static final _volumeFormatter = NumberFormat(AppConfig.volumeFormatPattern);

  /// 현재 가격 포맷팅.
  /// - 극단값(NaN, Infinity) 처리.
  /// @returns 포맷된 가격 문자열.
  String get formattedCurrentPrice {
    if (currentPrice.isNaN || currentPrice.isInfinite) {
      return '0.00';
    }
    return _priceFormatter.format(currentPrice);
  }

  /// 24시간 가격 변동률 포맷팅.
  /// - 극단값 처리, 퍼센트 기호 포함.
  /// @returns 포맷된 변동률 문자열 (예: '+5.00%', '-3.25%').
  String get formattedPriceChangePercentage {
    if (priceChangePercentage24h.isNaN || priceChangePercentage24h.isInfinite) {
      return '0.00%';
    }
    return '${_percentageFormatter.format(priceChangePercentage24h)}%';
  }

  /// 24시간 거래량 포맷팅.
  /// - 극단값 처리.
  /// @returns 포맷된 거래량 문자열.
  String get formattedVolume {
    if (volume24h.isNaN || volume24h.isInfinite) {
      return '0.00';
    }
    return _volumeFormatter.format(volume24h);
  }

  /// 가격 상승 여부.
  bool get isPriceUp => priceChange24h > 0;

  /// 가격 하락 여부.
  bool get isPriceDown => priceChange24h < 0;

  /// 가격 안정 여부 (변동 없음).
  bool get isPriceStable => priceChange24h == 0;

  /// 코인 이름 추출.
  /// - 거래소별 심볼 형식에 따라 파싱.
  /// @throws [InvalidInputException] 유효하지 않은 심볼 형식.
  /// @returns 코인 이름 (예: 'BTC', 'ETH').
  String get coinName {
    if (symbol.isEmpty) {
      throw InvalidInputException(message: 'Symbol cannot be empty');
    }

    try {
      switch (platform) {
        case ExchangePlatform.upbit:
          final parts = symbol.split('-');
          if (parts.length != 2) throw InvalidInputException(message: 'Invalid Upbit symbol format: $symbol');
          return parts.last;
        case ExchangePlatform.binance:
        case ExchangePlatform.bybit:
          final name = symbol.replaceAll(RegExp('(USDT|BTC)\$'), '');
          if (name.isEmpty) throw InvalidInputException(message: 'Invalid ${platform.name} symbol format: $symbol');
          return name;
        case ExchangePlatform.bithumb:
          final parts = symbol.split('_');
          if (parts.isEmpty) throw InvalidInputException(message: 'Invalid Bithumb symbol format: $symbol');
          return parts.first;
      }
    } catch (e, stackTrace) {
      final metricLogger = Get.isRegistered<MetricLogger>(tag: DITags.metricLoggerTag)
          ? Get.find<MetricLogger>(tag: DITags.metricLoggerTag)
          : null;
      final signalBus = Get.isRegistered<SignalBus>(tag: DITags.signalBusTag)
          ? Get.find<SignalBus>(tag: DITags.signalBusTag)
          : null;

      metricLogger?.incrementCounter('format_errors', labels: {'platform': platform.toString(), 'method': 'coinName'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(CoinNameParseErrorEvent(
        symbol: symbol,
        platform: platform.toString(),
        error: e.toString(),
      ));
      
      throw InvalidInputException(message: 'Failed to parse coin name: $e');
    }
  }

  /// 포맷팅 로깅 및 메트릭 기록.
  /// - [method]: 호출된 포맷팅 메서드.
  /// - [metricLogger]: 메트릭 로거.
  /// - [signalBus]: 이벤트 버스.
  void logFormat(String method, {MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('format_calls', labels: {'platform': platform.toString(), 'method': method});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(MarketFormattedEvent(method, symbol));
  }
}