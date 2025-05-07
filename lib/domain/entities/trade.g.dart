// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Trade _$TradeFromJson(Map<String, dynamic> json) => Trade(
      symbol: json['symbol'] as String,
      price: (json['price'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
      timestamp: (json['timestamp'] as num).toInt(),
      isBuy: json['isBuy'] as bool,
      sequentialId: json['sequentialId'] as String,
    );

Map<String, dynamic> _$TradeToJson(Trade instance) => <String, dynamic>{
      'symbol': instance.symbol,
      'price': instance.price,
      'volume': instance.volume,
      'timestamp': instance.timestamp,
      'isBuy': instance.isBuy,
      'sequentialId': instance.sequentialId,
    };
