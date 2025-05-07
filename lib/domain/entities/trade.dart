import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'trade.g.dart';

/// Represents a cryptocurrency trade event from WebSocket or API.
@JsonSerializable()
class Trade extends Equatable {
  /// Market symbol (e.g., KRW-BTC).
  final String symbol;

  /// Trade price in base currency.
  final double price;

  /// Trade volume in quote currency.
  final double volume;

  /// Timestamp of the trade in milliseconds since epoch.
  final int timestamp;

  /// Whether the trade is a buy (true) or sell (false).
  final bool isBuy;

  /// Unique sequential ID of the trade.
  final String sequentialId;

  const Trade({
    required this.symbol,
    required this.price,
    required this.volume,
    required this.timestamp,
    required this.isBuy,
    required this.sequentialId,
  });

  factory Trade.fromJson(Map<String, dynamic> json) => _$TradeFromJson(json);

  Map<String, dynamic> toJson() => _$TradeToJson(this);

  @override
  List<Object> get props => [symbol, price, volume, timestamp, isBuy, sequentialId];
}