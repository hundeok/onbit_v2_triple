import 'package:json_annotation/json_annotation.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';

part 'trade_model.g.dart';

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

  factory TradeModel.fromJson(Map<String, dynamic> json) => _$TradeModelFromJson(json);
  Map<String, dynamic> toJson() => _$TradeModelToJson(this);

  static TradeModel fromExchangeJson(Map<String, dynamic> json) {
    final platform = _parsePlatform(json['platform']);
    switch (platform) {
      case TradePlatform.upbit:
        return _parseUpbitTrade(json);
      case TradePlatform.binance:
        return _parseBinanceTrade(json);
      case TradePlatform.bybit:
        return _parseBybitTrade(json);
      case TradePlatform.bithumb:
        return _parseBithumbTrade(json);
    }
  }

  static TradePlatform _parsePlatform(dynamic platformValue) {
    if (platformValue is TradePlatform) return platformValue;
    final str = platformValue.toString().toLowerCase();
    return TradePlatform.values.firstWhere(
      (e) => e.toString().split('.').last == str,
      orElse: () => TradePlatform.upbit,
    );
  }

  static TradeModel _parseUpbitTrade(Map<String, dynamic> json) {
    final symbol = json['market'] ?? '';
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
      isBuy: json['side']?.toLowerCase() == 'bid',
      sequentialId: json['sequentialId']?.toString() ?? '',
    );
  }

  static TradeModel _parseBinanceTrade(Map<String, dynamic> json) {
    final symbol = json['symbol'] ?? json['s'] ?? '';
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

  static TradeModel _parseBybitTrade(Map<String, dynamic> json) {
    final data = json['data'] is Map ? json['data'] : json;
    final symbol = data['symbol'] ?? '';
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
      isBuy: data['side']?.toLowerCase() == 'buy' || data['isBuy'] == true,
      sequentialId: data['id']?.toString() ?? data['sequentialId']?.toString() ?? '',
    );
  }

  static TradeModel _parseBithumbTrade(Map<String, dynamic> json) {
    final symbol = json['symbol'] ?? '';
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
      isBuy: (json['bs'] ?? json['side'])?.toLowerCase() == 'b' || json['isBuy'] == true,
      sequentialId: (json['td'] ?? json['sequentialId'])?.toString() ?? '',
    );
  }

  // 헬퍼 메서드: 문자열이나 숫자를 double로 변환
  static double _d(dynamic v) => v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
  
  // 헬퍼 메서드: 문자열이나 숫자를 int 타임스탬프로 변환
  static int _t(dynamic v) => v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);

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
}