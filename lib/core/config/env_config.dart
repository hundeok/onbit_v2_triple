import 'package:onbit_v2_triple/core/config/app_config.dart';

class ExchangeConfig {
  final String baseUrl;
  final String symbolsEndpoint;
  final String symbolKey;
  final String marketPrefix;
  final String wsUrl;

  const ExchangeConfig({
    required this.baseUrl,
    required this.symbolsEndpoint,
    required this.symbolKey,
    required this.marketPrefix,
    required this.wsUrl,
  });

  static final Map<ExchangePlatform, ExchangeConfig> _configs = {
    ExchangePlatform.upbit: const ExchangeConfig(
      baseUrl: 'https://api.upbit.com/v1',
      symbolsEndpoint: '/market/all',
      symbolKey: 'market',
      marketPrefix: 'KRW-',
      wsUrl: 'wss://api.upbit.com/websocket/v1',
    ),
    ExchangePlatform.binance: const ExchangeConfig(
      baseUrl: 'https://api.binance.com',
      symbolsEndpoint: '/api/v3/exchangeInfo',
      symbolKey: 'symbol',
      marketPrefix: 'USDT',
      wsUrl: 'wss://stream.binance.com:9443/ws',
    ),
    ExchangePlatform.bybit: const ExchangeConfig(
      baseUrl: 'https://api.bybit.com',
      symbolsEndpoint: '/v5/market/instruments-info?category=spot',
      symbolKey: 'symbol',
      marketPrefix: 'USDT',
      wsUrl: 'wss://stream.bybit.com/v5/public/spot',
    ),
    ExchangePlatform.bithumb: const ExchangeConfig(
      baseUrl: 'https://api.bithumb.com',
      symbolsEndpoint: '/public/ticker/ALL',
      symbolKey: 'market',
      marketPrefix: 'KRW-',
      wsUrl: 'wss://pubwss.bithumb.com/pub/ws',
    ),
  };

  static ExchangeConfig getConfig(ExchangePlatform platform) {
    return _configs[platform]!;
  }
}