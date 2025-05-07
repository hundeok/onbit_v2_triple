import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:onbit_v2_triple/core/logger/app_logger.dart';

enum ExchangePlatform {
  upbit,
  binance,
  bybit,
  bithumb,
}

class ExchangeConfig {
  final String baseUrl;
  final String symbolsEndpoint;
  final String symbolKey;
  final String marketPrefix;

  const ExchangeConfig({
    required this.baseUrl,
    required this.symbolsEndpoint,
    required this.symbolKey,
    required this.marketPrefix,
  });

  static const Map<ExchangePlatform, ExchangeConfig> _configs = {
    ExchangePlatform.upbit: ExchangeConfig(
      baseUrl: 'https://api.upbit.com/v1',
      symbolsEndpoint: '/market/all',
      symbolKey: 'market',
      marketPrefix: 'KRW-',
    ),
    ExchangePlatform.binance: ExchangeConfig(
      baseUrl: 'https://api.binance.com',
      symbolsEndpoint: '/api/v3/exchangeInfo',
      symbolKey: 'symbol',
      marketPrefix: 'USDT',
    ),
    ExchangePlatform.bybit: ExchangeConfig(
      baseUrl: 'https://api.bybit.com',
      symbolsEndpoint: '/v5/market/instruments-info?category=spot',
      symbolKey: 'symbol',
      marketPrefix: 'USDT',
    ),
    ExchangePlatform.bithumb: ExchangeConfig(
      baseUrl: 'https://api.bithumb.com',
      symbolsEndpoint: '/public/ticker/ALL',
      symbolKey: 'market',
      marketPrefix: 'KRW-',
    ),
  };

  static ExchangeConfig getConfig(ExchangePlatform platform) {
    return _configs[platform]!;
  }
}

class MarketDataSource {
  final ExchangePlatform platform;
  final http.Client _client;
  static const int _timeoutSeconds = 10;
  late final ExchangeConfig _config;
  final AppLogger _logger;

  MarketDataSource({
    this.platform = ExchangePlatform.upbit,
    http.Client? client,
    required AppLogger logger,
  }) : _client = client ?? http.Client(), _logger = logger {
    _config = ExchangeConfig.getConfig(platform);
  }

  Future<List<String>> fetchAllSymbols() async {
    try {
      final uri = Uri.parse('${_config.baseUrl}${_config.symbolsEndpoint}');
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: _timeoutSeconds), onTimeout: () {
        throw Exception('Request timed out after $_timeoutSeconds seconds');
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> marketsData = data as List<dynamic>;

        final List<String> symbols = marketsData
            .map((item) => item[_config.symbolKey] as String)
            .where((symbol) => symbol.startsWith(_config.marketPrefix))
            .toList();

        _logger.logInfo('Fetched ${symbols.length} symbols');
        return symbols;
      } else {
        throw Exception('Failed to load symbols: ${response.statusCode}');
      }
    } catch (e) {
      _logger.logError('Error fetching symbols', error: e);
      throw Exception('Error fetching symbols: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}