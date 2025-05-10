// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TradeModel _$TradeModelFromJson(Map<String, dynamic> json) => TradeModel(
      platform: $enumDecode(_$TradePlatformEnumMap, json['platform']),
      symbol: json['symbol'] as String,
      baseCurrency: json['baseCurrency'] as String,
      targetCurrency: json['targetCurrency'] as String,
      price: (json['price'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
      timestamp: (json['timestamp'] as num).toInt(),
      isBuy: json['isBuy'] as bool,
      sequentialId: json['sequentialId'] as String,
      tradeType: $enumDecodeNullable(_$TradeTypeEnumMap, json['tradeType']) ??
          TradeType.spot,
    );

Map<String, dynamic> _$TradeModelToJson(TradeModel instance) =>
    <String, dynamic>{
      'platform': _$TradePlatformEnumMap[instance.platform]!,
      'symbol': instance.symbol,
      'baseCurrency': instance.baseCurrency,
      'targetCurrency': instance.targetCurrency,
      'price': instance.price,
      'volume': instance.volume,
      'timestamp': instance.timestamp,
      'isBuy': instance.isBuy,
      'sequentialId': instance.sequentialId,
      'tradeType': _$TradeTypeEnumMap[instance.tradeType]!,
    };

const _$TradePlatformEnumMap = {
  TradePlatform.upbit: 'upbit',
  TradePlatform.binance: 'binance',
  TradePlatform.bybit: 'bybit',
  TradePlatform.bithumb: 'bithumb',
};

const _$TradeTypeEnumMap = {
  TradeType.spot: 'spot',
  TradeType.futures: 'futures',
  TradeType.margin: 'margin',
};
