import 'package:get/get.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/di/tags.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';

part 'trade_model.g.dart';

/// TradeModel 관련 SignalBus 이벤트 클래스들
/// 모델 파싱 성공 이벤트
class TradeModelParsedEvent extends SignalEvent {
  final String symbol;
  final String platform;
  
  TradeModelParsedEvent({
    required this.symbol,
    required this.platform,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'trade_model_parsed',
    'symbol': symbol,
    'platform': platform,
    'sequentialId': sequentialId.toString(),
  };
}

/// 모델 유효성 검증 성공 이벤트
class TradeModelValidatedEvent extends SignalEvent {
  final String symbol;
  final String platform;
  
  TradeModelValidatedEvent({
    required this.symbol,
    required this.platform,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'trade_model_validated',
    'symbol': symbol,
    'platform': platform,
    'sequentialId': sequentialId.toString(),
  };
}

/// 데이터 파싱 에러 이벤트
class DataParsingErrorEvent extends SignalEvent {
  final String message;
  final String error;
  
  DataParsingErrorEvent({
    required this.message,
    required this.error,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'data_parsing_error',
    'message': message,
    'error': error,
    'sequentialId': sequentialId.toString(),
  };
}

/// 거래 데이터를 나타내는 모델 클래스.
/// - [Trade] 엔티티를 상속, JSON 직렬화 지원.
/// - [RealMarketDataSource], [SocketTradeSource]에서 생성, [TradeRepositoryImpl]에서 사용.
/// @see [JsonSerializable] for JSON serialization.
@JsonSerializable(explicitToJson: true)
class TradeModel extends Trade {
  const TradeModel({
    required super.platform,
    required super.symbol,
    required super.baseCurrency,
    required super.targetCurrency,
    required super.price,
    required super.volume,
    required super.timestamp,
    required super.isBuy,
    required super.sequentialId,
    super.tradeType = TradeType.spot,
  });

  /// JSON에서 [TradeModel] 생성.
  factory TradeModel.fromJson(Map<String, dynamic> json) => _$TradeModelFromJson(json);

  /// [TradeModel]을 JSON으로 변환.
  Map<String, dynamic> toJson() => _$TradeModelToJson(this);

  /// 거래소별 JSON에서 [TradeModel] 생성.
  /// - [json]: 거래소별 JSON 데이터.
  /// @throws [DataParsingException] 파싱 실패 시.
  static TradeModel fromExchangeJson(
    Map<String, dynamic> json, {
    MetricLogger? metricLogger,
    SignalBus? signalBus,
  }) {
    try {
      final platform = _parsePlatform(json['platform']);
      TradeModel model;
      switch (platform) {
        case TradePlatform.upbit:
          model = _parseUpbitTrade(json);
          break;
        case TradePlatform.binance:
          model = _parseBinanceTrade(json);
          break;
        case TradePlatform.bybit:
          model = _parseBybitTrade(json);
          break;
        case TradePlatform.bithumb:
          model = _parseBithumbTrade(json);
          break;
      }
      metricLogger?.incrementCounter('trade_model_parses', labels: {'platform': platform.toString(), 'status': 'success'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(TradeModelParsedEvent(
        symbol: model.symbol,
        platform: platform.toString(),
      ));
      
      return model.validate();
    } catch (e, stackTrace) {
      metricLogger?.incrementCounter('trade_model_parses', labels: {'platform': json['platform']?.toString() ?? 'unknown', 'status': 'failure'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(DataParsingErrorEvent(
        message: 'Failed to parse TradeModel JSON',
        error: e.toString(),
      ));
      
      throw DataParsingException(message: 'Failed to parse TradeModel: $e');
    }
  }

  /// 플랫폼 파싱.
  /// - [platformValue]: 플랫폼 값 (문자열 또는 enum).
  /// @throws [DataParsingException] 알 수 없는 플랫폼.
  static TradePlatform _parsePlatform(dynamic platformValue) {
    if (platformValue is TradePlatform) return platformValue;
    final str = platformValue?.toString().toLowerCase() ?? '';
    try {
      return TradePlatform.values.firstWhere(
        (e) => e.toString().split('.').last == str,
      );
    } catch (e) {
      throw DataParsingException(message: 'Unknown platform: $str');
    }
  }

  /// Upbit 거래 JSON 파싱.
  static TradeModel _parseUpbitTrade(Map<String, dynamic> json) {
    final symbol = json['market']?.toString() ?? 'UNKNOWN_UPBIT';
    final parts = symbol.split('-');
    final base = parts.isNotEmpty ? parts[0] : 'KRW';
    final target = parts.length > 1 ? parts[1] : '';
    return TradeModel(
      platform: TradePlatform.upbit,
      symbol: symbol,
      baseCurrency: base,
      targetCurrency: target,
      price: _d(json['price']),
      volume: _d(json['volume']),
      timestamp: _t(json['timestamp']),
      isBuy: json['side']?.toString().toLowerCase() == 'bid',
      sequentialId: json['sequentialId']?.toString() ?? '',
    );
  }

  /// Binance 거래 JSON 파싱.
  static TradeModel _parseBinanceTrade(Map<String, dynamic> json) {
    final symbol = json['symbol']?.toString() ?? json['s']?.toString() ?? 'UNKNOWN_BINANCE';
    final base = symbol.endsWith('USDT') ? 'USDT' : symbol.endsWith('BTC') ? 'BTC' : '';
    final target = base.isNotEmpty ? symbol.replaceAll(base, '') : symbol;
    return TradeModel(
      platform: TradePlatform.binance,
      symbol: symbol,
      baseCurrency: base,
      targetCurrency: target,
      price: _d(json['p'] ?? json['price']),
      volume: _d(json['q'] ?? json['volume']),
      timestamp: _t(json['T'] ?? json['timestamp']),
      isBuy: json['m'] == false || json['isBuy'] == true,
      sequentialId: (json['a'] ?? json['sequentialId'])?.toString() ?? '',
    );
  }

  /// Bybit 거래 JSON 파싱.
  static TradeModel _parseBybitTrade(Map<String, dynamic> json) {
    final data = json['data'] is Map ? json['data'] as Map<String, dynamic> : json;
    final symbol = data['symbol']?.toString() ?? 'UNKNOWN_BYBIT';
    final base = symbol.endsWith('USDT') ? 'USDT' : '';
    final target = base.isNotEmpty ? symbol.substring(0, symbol.length - 4) : symbol;
    return TradeModel(
      platform: TradePlatform.bybit,
      symbol: symbol,
      baseCurrency: base,
      targetCurrency: target,
      price: _d(data['price']),
      volume: _d(data['size'] ?? data['volume']),
      timestamp: _t(data['timestamp']),
      isBuy: data['side']?.toString().toLowerCase() == 'buy' || data['isBuy'] == true,
      sequentialId: (data['id'] ?? data['sequentialId'])?.toString() ?? '',
    );
  }

  /// Bithumb 거래 JSON 파싱.
  static TradeModel _parseBithumbTrade(Map<String, dynamic> json) {
    final symbol = json['symbol']?.toString() ?? 'UNKNOWN_BITHUMB';
    final parts = symbol.split('_');
    final base = parts.length > 1 ? parts[1] : 'KRW';
    final target = parts.isNotEmpty ? parts[0] : '';
    return TradeModel(
      platform: TradePlatform.bithumb,
      symbol: symbol,
      baseCurrency: base,
      targetCurrency: target,
      price: _d(json['p'] ?? json['price']),
      volume: _d(json['v'] ?? json['volume']),
      timestamp: _t(json['t'] ?? json['timestamp']),
      isBuy: (json['bs'] ?? json['side'])?.toString().toLowerCase() == 'b' || json['isBuy'] == true,
      sequentialId: (json['td'] ?? json['sequentialId'])?.toString() ?? '',
    );
  }

  /// 안전한 double 변환.
  /// - [v]: 원본 값.
  /// @returns 정규화된 double, NaN/Infinity는 0.0.
  static double _d(dynamic v) {
    if (v == null) return 0.0;
    final result = v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    return result.isNaN || result.isInfinite ? 0.0 : result;
  }

  /// 안전한 int 타임스탬프 변환.
  /// - [v]: 원본 값.
  /// @returns 유효한 밀리초 타임스탬프, 유효하지 않으면 현재 시간.
  static int _t(dynamic v) {
    if (v is int && v > 0) return v;
    final result = int.tryParse(v?.toString() ?? '');
    if (result != null && result > 0) return result;
    
    final metricLogger = Get.isRegistered<MetricLogger>(tag: DITags.metricLoggerTag)
        ? Get.find<MetricLogger>(tag: DITags.metricLoggerTag)
        : null;
    metricLogger?.incrementCounter('timestamp_fallbacks', labels: {'source': 'TradeModel'});
    
    return DateTime.now().millisecondsSinceEpoch;
  }

  @override
  TradeModel copyWith({
    TradePlatform? platform,
    String? symbol,
    String? baseCurrency,
    String? targetCurrency,
    double? price,
    double? volume,
    int? timestamp,
    bool? isBuy,
    String? sequentialId,
    TradeType? tradeType,
  }) {
    return TradeModel(
      platform: platform ?? this.platform,
      symbol: symbol ?? this.symbol,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      price: price ?? this.price,
      volume: volume ?? this.volume,
      timestamp: timestamp ?? this.timestamp,
      isBuy: isBuy ?? this.isBuy,
      sequentialId: sequentialId ?? this.sequentialId,
      tradeType: tradeType ?? this.tradeType,
    );
  }

  /// 입력 데이터 검증.
  /// - [symbol], [sequentialId] 비어있지 않아야 함.
  /// - [timestamp], [price], [volume] 음수 불가.
  /// @throws [InvalidInputException] 유효하지 않은 입력 시.
  @override
  TradeModel validate({MetricLogger? metricLogger, SignalBus? signalBus}) {
    if (symbol.isEmpty) {
      throw InvalidInputException(message: 'Symbol cannot be empty');
    }
    if (sequentialId.isEmpty) {
      throw InvalidInputException(message: 'SequentialId cannot be empty');
    }
    if (timestamp < 0) {
      throw InvalidInputException(message: 'Timestamp cannot be negative');
    }
    if (price < 0) {
      throw InvalidInputException(message: 'Price cannot be negative');
    }
    if (volume < 0) {
      throw InvalidInputException(message: 'Volume cannot be negative');
    }
    
    // Trade 부모 클래스의 validate 메서드는 호출하지 않음 (중복 로직)
    metricLogger?.incrementCounter('trade_model_validations', labels: {'status': 'success'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(TradeModelValidatedEvent(
      symbol: symbol,
      platform: platform.toString(),
    ));
    
    return this;
  }
}