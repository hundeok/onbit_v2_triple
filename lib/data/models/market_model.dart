import 'package:equatable/equatable.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';
import 'package:onbit_v2_triple/data/models/market_json_parser.dart';

/// MarketModel 관련 SignalBus 이벤트 클래스들
/// 모델 파싱 성공 이벤트
class MarketModelParsedEvent extends SignalEvent {
  final String symbol;
  
  MarketModelParsedEvent(this.symbol) 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'market_model_parsed',
    'symbol': symbol,
    'sequentialId': sequentialId.toString(),
  };
}

/// 모델 파싱 에러 이벤트
class MarketModelParseErrorEvent extends SignalEvent {
  final String message;
  final String error;
  
  MarketModelParseErrorEvent({
    required this.message,
    required this.error,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'market_model_parse_error',
    'message': message,
    'error': error,
    'sequentialId': sequentialId.toString(),
  };
}

/// 마켓(거래 페어) 정보를 나타내는 모델 클래스.
/// - [RealMarketDataSource]에서 생성, [TradeRepositoryImpl]에서 사용.
/// - [Equatable]로 불변성 및 비교 최적화.
/// @see [MarketJsonParser] for JSON parsing logic.
class MarketModel extends Equatable {
  final String symbol;
  final double currentPrice;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double volume24h;
  final double priceChange24h;
  final double priceChangePercentage24h;
  final int timestamp;
  final ExchangePlatform platform;

  const MarketModel({
    required this.symbol,
    required this.currentPrice,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.volume24h,
    required this.priceChange24h,
    required this.priceChangePercentage24h,
    required this.timestamp,
    required this.platform,
  });

  /// JSON 데이터로 모델 생성.
  /// - [json]: 거래소별 JSON 데이터.
  /// - [platform]: 거래소 플랫폼.
  /// @throws [DataParsingException] 파싱 실패 시.
  factory MarketModel.fromJson(dynamic json, ExchangePlatform platform, {MetricLogger? metricLogger, SignalBus? signalBus}) {
    try {
      final model = MarketJsonParser.parse(json, platform);
      metricLogger?.incrementCounter('market_model_parses', labels: {'platform': platform.toString(), 'status': 'success'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(MarketModelParsedEvent(model.symbol));
      
      return model;
    } catch (e, stackTrace) {
      metricLogger?.incrementCounter('market_model_parses', labels: {'platform': platform.toString(), 'status': 'failure'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(MarketModelParseErrorEvent(
        message: 'Failed to parse MarketModel',
        error: e.toString(),
      ));
      
      throw DataParsingException(message: 'Failed to parse MarketModel: $e');
    }
  }

  /// 모델을 JSON으로 변환.
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'current_price': currentPrice,
      'open_price': openPrice,
      'high_price': highPrice,
      'low_price': lowPrice,
      'volume_24h': volume24h,
      'price_change_24h': priceChange24h,
      'price_change_percentage_24h': priceChangePercentage24h,
      'timestamp': timestamp,
      'platform': platform.name,
    };
  }

  /// 모델 복사본 생성.
  /// - 불변 객체 업데이트용.
  /// @returns 새로운 [MarketModel] 인스턴스.
  MarketModel copyWith({
    String? symbol,
    double? currentPrice,
    double? openPrice,
    double? highPrice,
    double? lowPrice,
    double? volume24h,
    double? priceChange24h,
    double? priceChangePercentage24h,
    int? timestamp,
    ExchangePlatform? platform,
  }) {
    return MarketModel(
      symbol: symbol ?? this.symbol,
      currentPrice: currentPrice ?? this.currentPrice,
      openPrice: openPrice ?? this.openPrice,
      highPrice: highPrice ?? this.highPrice,
      lowPrice: lowPrice ?? this.lowPrice,
      volume24h: volume24h ?? this.volume24h,
      priceChange24h: priceChange24h ?? this.priceChange24h,
      priceChangePercentage24h: priceChangePercentage24h ?? this.priceChangePercentage24h,
      timestamp: timestamp ?? this.timestamp,
      platform: platform ?? this.platform,
    );
  }

  /// Timestamp를 DateTime으로 변환.
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  @override
  List<Object?> get props => [
        symbol,
        currentPrice,
        openPrice,
        highPrice,
        lowPrice,
        volume24h,
        priceChange24h,
        priceChangePercentage24h,
        timestamp,
        platform,
      ];

  /// 입력 데이터 검증 및 정규화.
  /// - [symbol]: 마켓 심볼, 비어있지 않아야 함.
  /// - [timestamp]: 음수 불가.
  /// - [priceChangePercentage24h]: 극단값(-100% ~ 1000%) 제한.
  /// @throws [InvalidInputException] 유효하지 않은 입력 시.
  MarketModel validate() {
    if (symbol.isEmpty) {
      throw InvalidInputException(message: 'Symbol cannot be empty');
    }
    if (timestamp < 0) {
      throw InvalidInputException(message: 'Timestamp cannot be negative');
    }
    if (priceChangePercentage24h < -100 || priceChangePercentage24h > 1000) {
      throw InvalidInputException(message: 'Price change percentage out of range: $priceChangePercentage24h');
    }
    return this;
  }
}