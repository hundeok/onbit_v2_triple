import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// 거래소별 플랫폼 구분
enum TradePlatform {
  upbit,
  binance,
  bybit,
  bithumb
}

/// 거래 타입
enum TradeType {
  spot,
  futures,
  margin
}

/// WebSocket 또는 API로부터 수신한 암호화폐 거래 이벤트 표현
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

  /// 거래 금액 (가격 * 볼륨)
  double get amount => price * volume;

  /// 거래 시간을 DateTime 객체로 변환
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  /// 가격의 문자열 표현 (UI 레이어에서 사용)
  String get formattedPrice {
    final formatter = NumberFormat('#,##0.00####');
    return formatter.format(price);
  }

  /// 거래가 매수인지 매도인지 문자열로 표현 (UI 레이어에서 사용)
  String get tradeDirection => isBuy ? '매수' : '매도';

  /// 거래량의 문자열 표현 (UI 레이어에서 사용)
  String get formattedVolume {
    if (volume < 0.001) {
      return volume.toStringAsFixed(8);
    } else if (volume < 1) {
      return volume.toStringAsFixed(6);
    } else if (volume < 1000) {
      return volume.toStringAsFixed(4);
    } else {
      final formatter = NumberFormat('#,##0.##');
      return formatter.format(volume);
    }
  }

  /// 거래 금액의 문자열 표현 (UI 레이어에서 사용)
  String get formattedAmount {
    final formatter = NumberFormat('#,##0.##');
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
    tradeType
  ];

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
}