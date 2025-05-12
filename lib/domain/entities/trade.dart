import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';

/// 거래소별 플랫폼 구분.
enum TradePlatform {
  upbit,
  binance,
  bybit,
  bithumb,
}

/// 거래 타입.
enum TradeType {
  spot,
  futures,
  margin,
}

/// Trade 엔티티 관련 이벤트 클래스들
/// 거래 유효성 검증 이벤트
class TradeValidatedEvent extends SignalEvent {
  final String symbol;
  final String platform;
  
  TradeValidatedEvent({
    required this.symbol,
    required this.platform,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'trade_validated',
    'symbol': symbol,
    'platform': platform,
    'sequentialId': sequentialId.toString(),
  };
}

/// 유효성 검증 오류 이벤트
class ValidationErrorEvent extends SignalEvent {
  final String entity;
  final String field;
  final String message;
  
  ValidationErrorEvent({
    required this.entity,
    required this.field,
    required this.message,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'validation_error',
    'entity': entity,
    'field': field,
    'message': message,
    'sequentialId': sequentialId.toString(),
  };
}

/// 암호화폐 거래 이벤트 엔티티.
/// - WebSocket 또는 API로부터 수신한 거래 데이터 표현.
/// - [TradeModel]에서 상속, [TradeRepositoryImpl], [SocketTradeSource]에서 사용.
/// @see [Equatable] for comparison optimization.
class Trade extends Equatable {
  final TradePlatform platform;
  final String symbol;
  final String baseCurrency;
  final String targetCurrency;
  final double price;
  final double volume;
  final int timestamp;
  final bool isBuy;
  final String sequentialId;
  final TradeType tradeType;

  const Trade({
    required this.platform,
    required this.symbol,
    required this.baseCurrency,
    required this.targetCurrency,
    required this.price,
    required this.volume,
    required this.timestamp,
    required this.isBuy,
    required this.sequentialId,
    this.tradeType = TradeType.spot,
  });

  /// 거래 금액 (가격 * 볼륨).
  /// - NaN/Infinity 처리.
  double get amount {
    final result = price * volume;
    return result.isNaN || result.isInfinite ? 0.0 : result;
  }

  /// 거래 시간을 DateTime 객체로 변환.
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  /// 가격 포맷팅 (UI용).
  /// - [AppConfig]에서 포맷 설정 참조.
  /// @returns 포맷된 가격 문자열.
  String get formattedPrice {
    if (price.isNaN || price.isInfinite) return '0.00';
    final formatter = NumberFormat(AppConfig.priceFormatPattern);
    return formatter.format(price);
  }

  /// 거래 방향 (매수/매도, UI용).
  String get tradeDirection => isBuy ? '매수' : '매도';

  /// 거래량 포맷팅 (UI용).
  /// - 소수점 동적 조정, [AppConfig] 참조.
  /// @returns 포맷된 거래량 문자열.
  String get formattedVolume {
    if (volume.isNaN || volume.isInfinite) return '0.00';
    if (volume < 0.001) {
      return volume.toStringAsFixed(8);
    } else if (volume < 1) {
      return volume.toStringAsFixed(6);
    } else if (volume < 1000) {
      return volume.toStringAsFixed(4);
    }
    final formatter = NumberFormat(AppConfig.volumeFormatPattern);
    return formatter.format(volume);
  }

  /// 거래 금액 포맷팅 (UI용).
  /// - [AppConfig] 참조.
  /// @returns 포맷된 금액 문자열.
  String get formattedAmount {
    if (amount.isNaN || amount.isInfinite) return '0.00';
    final formatter = NumberFormat(AppConfig.amountFormatPattern);
    return formatter.format(amount);
  }

  @override
  List<Object> get props => [
        platform,
        symbol,
        baseCurrency,
        targetCurrency,
        price,
        volume,
        timestamp,
        isBuy,
        sequentialId,
        tradeType,
      ];

  /// 엔티티 복사본 생성.
  /// - 불변 객체 업데이트용.
  /// @returns 새로운 [Trade] 인스턴스.
  Trade copyWith({
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
    return Trade(
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
  Trade validate({MetricLogger? metricLogger, SignalBus? signalBus}) {
    if (symbol.isEmpty) {
      metricLogger?.incrementCounter('validation_errors', labels: {'entity': 'Trade', 'field': 'symbol'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(ValidationErrorEvent(
        entity: 'Trade',
        field: 'symbol',
        message: 'Symbol cannot be empty',
      ));
      
      throw InvalidInputException(message: 'Symbol cannot be empty');
    }
    if (sequentialId.isEmpty) {
      metricLogger?.incrementCounter('validation_errors', labels: {'entity': 'Trade', 'field': 'sequentialId'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(ValidationErrorEvent(
        entity: 'Trade',
        field: 'sequentialId',
        message: 'SequentialId cannot be empty',
      ));
      
      throw InvalidInputException(message: 'SequentialId cannot be empty');
    }
    if (timestamp < 0) {
      metricLogger?.incrementCounter('validation_errors', labels: {'entity': 'Trade', 'field': 'timestamp'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(ValidationErrorEvent(
        entity: 'Trade',
        field: 'timestamp',
        message: 'Timestamp cannot be negative',
      ));
      
      throw InvalidInputException(message: 'Timestamp cannot be negative');
    }
    if (price < 0) {
      metricLogger?.incrementCounter('validation_errors', labels: {'entity': 'Trade', 'field': 'price'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(ValidationErrorEvent(
        entity: 'Trade',
        field: 'price',
        message: 'Price cannot be negative',
      ));
      
      throw InvalidInputException(message: 'Price cannot be negative');
    }
    if (volume < 0) {
      metricLogger?.incrementCounter('validation_errors', labels: {'entity': 'Trade', 'field': 'volume'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(ValidationErrorEvent(
        entity: 'Trade',
        field: 'volume',
        message: 'Volume cannot be negative',
      ));
      
      throw InvalidInputException(message: 'Volume cannot be negative');
    }
    
    metricLogger?.incrementCounter('trade_validations', labels: {'status': 'success'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(TradeValidatedEvent(
      symbol: symbol,
      platform: platform.toString(),
    ));
    
    return this;
  }
}