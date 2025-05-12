import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/di/tags.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';
import 'package:onbit_v2_triple/data/models/market_model.dart';

/// MarketJsonParser 관련 SignalBus 이벤트 클래스들
/// 마켓 파싱 성공 이벤트
class MarketParsedEvent extends SignalEvent {
  final String symbol;
  final ExchangePlatform platform;
  
  MarketParsedEvent(this.symbol, this.platform) 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'market_parsed',
    'symbol': symbol,
    'platform': platform.toString(),
    'sequentialId': sequentialId.toString(),
  };
}

/// 마켓 파싱 에러 이벤트
class MarketParseErrorEvent extends SignalEvent {
  final String message;
  final String platform;
  final String error;
  
  MarketParseErrorEvent({
    required this.message,
    required this.platform,
    required this.error,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'market_parse_error',
    'message': message,
    'platform': platform,
    'error': error,
    'sequentialId': sequentialId.toString(),
  };
}

/// 거래소별 [MarketModel] JSON 파싱 유틸리티.
/// - [MarketModel.fromJson]에서 호출, 거래소별 데이터 형식을 표준화.
/// @throws [DataParsingException] 파싱 실패 시.
class MarketJsonParser {
  /// JSON 데이터를 [MarketModel]로 파싱.
  /// - [json]: 거래소별 JSON 데이터.
  /// - [platform]: 거래소 플랫폼.
  /// - [metricLogger]: 메트릭 로거 (선택).
  /// - [signalBus]: 이벤트 버스 (선택).
  /// @returns [MarketModel] 파싱된 모델.
  static MarketModel parse(
    dynamic json, 
    ExchangePlatform platform, {
    MetricLogger? metricLogger,
    SignalBus? signalBus,
  }) {
    try {
      if (json == null || (json is Map && json.isEmpty) || (json is List && json.isEmpty)) {
        throw DataParsingException(message: 'Invalid JSON data: empty or null');
      }

      MarketModel model;
      switch (platform) {
        case ExchangePlatform.upbit:
          model = _parseUpbitJson(json);
          break;
        case ExchangePlatform.binance:
          model = _parseBinanceJson(json);
          break;
        case ExchangePlatform.bybit:
          model = _parseBybitJson(json);
          break;
        case ExchangePlatform.bithumb:
          model = _parseBithumbJson(json);
          break;
      }

      metricLogger?.incrementCounter('market_json_parses', labels: {'platform': platform.toString(), 'status': 'success'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(MarketParsedEvent(model.symbol, platform));
      
      return model;
    } catch (e, stackTrace) {
      metricLogger?.incrementCounter('market_json_parses', labels: {'platform': platform.toString(), 'status': 'failure'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(MarketParseErrorEvent(
        message: 'Failed to parse MarketModel JSON',
        platform: platform.toString(),
        error: e.toString(),
      ));
      
      throw DataParsingException(message: 'Failed to parse MarketModel: $e');
    }
  }

  /// Timestamp 정규화.
  /// - [ts]: 원본 타임스탬프.
  /// @returns 유효한 밀리초 타임스탬프.
  static int _timestamp(dynamic ts) {
    if (ts is int && ts > 0) {
      return ts;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final metricLogger = Get.isRegistered<MetricLogger>(tag: DITags.metricLoggerTag)
        ? Get.find<MetricLogger>(tag: DITags.metricLoggerTag)
        : null;
    metricLogger?.incrementCounter('timestamp_fallbacks', labels: {'source': 'MarketJsonParser'});
    return now;
  }

  /// 안전한 double 변환.
  /// - [val]: 원본 값.
  /// @returns 정규화된 double 값, NaN/Infinity는 0.0.
  static double _d(Object? val) {
    if (val == null) return 0.0;
    if (val is num) {
      final result = val.toDouble();
      return result.isNaN || result.isInfinite ? 0.0 : result;
    }
    final parsed = double.tryParse(val.toString());
    return parsed != null && !parsed.isNaN && !parsed.isInfinite ? parsed : 0.0;
  }

  /// Upbit JSON 파싱.
  static MarketModel _parseUpbitJson(dynamic json) {
    final data = (json is List && json.isNotEmpty) ? json[0] : json as Map<String, dynamic>;
    final symbol = data['market']?.toString() ?? 'UNKNOWN_UPBIT';
    return MarketModel(
      symbol: symbol,
      currentPrice: _d(data['trade_price']),
      openPrice: _d(data['opening_price']),
      highPrice: _d(data['high_price']),
      lowPrice: _d(data['low_price']),
      volume24h: _d(data['acc_trade_volume_24h']),
      priceChange24h: _d(data['signed_change_price']),
      priceChangePercentage24h: _d(data['signed_change_rate']) * 100,
      timestamp: _timestamp(data['timestamp']),
      platform: ExchangePlatform.upbit,
    );
  }

  /// Binance JSON 파싱.
  static MarketModel _parseBinanceJson(dynamic json) {
    final data = json as Map<String, dynamic>;
    final symbol = data['symbol']?.toString() ?? 'UNKNOWN_BINANCE';
    if (data.containsKey('price')) {
      // 단순 가격 엔드포인트
      return MarketModel(
        symbol: symbol,
        currentPrice: _d(data['price']),
        openPrice: 0.0,
        highPrice: 0.0,
        lowPrice: 0.0,
        volume24h: 0.0,
        priceChange24h: 0.0,
        priceChangePercentage24h: 0.0,
        timestamp: _timestamp(null),
        platform: ExchangePlatform.binance,
      );
    }
    return MarketModel(
      symbol: symbol,
      currentPrice: _d(data['lastPrice']),
      openPrice: _d(data['openPrice']),
      highPrice: _d(data['highPrice']),
      lowPrice: _d(data['lowPrice']),
      volume24h: _d(data['volume']),
      priceChange24h: _d(data['priceChange']),
      priceChangePercentage24h: _d(data['priceChangePercent']),
      timestamp: _timestamp(data['closeTime']),
      platform: ExchangePlatform.binance,
    );
  }

  /// Bybit JSON 파싱.
  static MarketModel _parseBybitJson(dynamic json) {
    final data = json['result']?['list']?[0] ?? json as Map<String, dynamic>;
    final symbol = data['symbol']?.toString() ?? 'UNKNOWN_BYBIT';
    return MarketModel(
      symbol: symbol,
      currentPrice: _d(data['lastPrice']),
      openPrice: _d(data['openPrice']),
      highPrice: _d(data['highPrice24h']),
      lowPrice: _d(data['lowPrice24h']),
      volume24h: _d(data['volume24h']),
      priceChange24h: _d(data['price24hPcnt']) * _d(data['lastPrice']),
      priceChangePercentage24h: _d(data['price24hPcnt']) * 100,
      timestamp: _timestamp(null),
      platform: ExchangePlatform.bybit,
    );
  }

  /// Bithumb JSON 파싱.
  static MarketModel _parseBithumbJson(dynamic json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final symbol = data['symbol']?.toString() ?? 'UNKNOWN_BITHUMB';
    final closingPrice = _d(data['closing_price']);
    final openingPrice = _d(data['opening_price']);
    return MarketModel(
      symbol: symbol,
      currentPrice: closingPrice,
      openPrice: openingPrice,
      highPrice: _d(data['max_price']),
      lowPrice: _d(data['min_price']),
      volume24h: _d(data['units_traded_24H']),
      priceChange24h: closingPrice - openingPrice,
      priceChangePercentage24h: openingPrice != 0 ? ((closingPrice / openingPrice) - 1) * 100 : 0.0,
      timestamp: _timestamp(null),
      platform: ExchangePlatform.bithumb,
    );
  }
}