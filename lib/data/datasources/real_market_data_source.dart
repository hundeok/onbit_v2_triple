import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/data/datasources/market_data_source.dart';
import 'package:onbit_v2_triple/data/models/market_model.dart';
import 'package:onbit_v2_triple/data/models/trade_model.dart';

/// MarketDataSource 관련 SignalBus 이벤트 클래스들
/// 심볼 목록 불러오기 이벤트
class SymbolsFetchedEvent extends SignalEvent {
  final int count;
  
  SymbolsFetchedEvent({
    required this.count,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'symbols_fetched',
    'count': count,
    'sequentialId': sequentialId.toString(),
  };
}

/// 시장 가격 불러오기 이벤트
class MarketPriceFetchedEvent extends SignalEvent {
  final String symbol;
  final double price;
  
  MarketPriceFetchedEvent({
    required this.symbol,
    required this.price,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'market_price_fetched',
    'symbol': symbol,
    'price': price,
    'sequentialId': sequentialId.toString(),
  };
}

/// 다중 시장 가격 불러오기 이벤트
class MultipleMarketPricesFetchedEvent extends SignalEvent {
  final int count;
  final int failed;
  
  MultipleMarketPricesFetchedEvent({
    required this.count,
    required this.failed,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'multiple_market_prices_fetched',
    'count': count,
    'failed': failed,
    'sequentialId': sequentialId.toString(),
  };
}

/// 거래 내역 불러오기 이벤트
class TradesFetchedEvent extends SignalEvent {
  final String symbol;
  final int count;
  
  TradesFetchedEvent({
    required this.symbol,
    required this.count,
  }) : super(SignalEventType.trade, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'trades_fetched',
    'symbol': symbol,
    'count': count,
    'sequentialId': sequentialId.toString(),
  };
}

/// 캔들 데이터 불러오기 이벤트
class CandlesFetchedEvent extends SignalEvent {
  final String symbol;
  final String interval;
  final int count;
  
  CandlesFetchedEvent({
    required this.symbol,
    required this.interval,
    required this.count,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'candles_fetched',
    'symbol': symbol,
    'interval': interval,
    'count': count,
    'sequentialId': sequentialId.toString(),
  };
}

/// 거래량 기준 필터링 이벤트
class TradesFilteredByVolumeEvent extends SignalEvent {
  final String symbol;
  final int count;
  final double minAmount;
  
  TradesFilteredByVolumeEvent({
    required this.symbol,
    required this.count,
    required this.minAmount,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'trades_filtered_by_volume',
    'symbol': symbol,
    'count': count,
    'minAmount': minAmount,
    'sequentialId': sequentialId.toString(),
  };
}

/// 시간 범위 기준 필터링 이벤트
class TradesFilteredByTimeEvent extends SignalEvent {
  final String symbol;
  final int count;
  final int startTime;
  final int endTime;
  
  TradesFilteredByTimeEvent({
    required this.symbol,
    required this.count,
    required this.startTime,
    required this.endTime,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'trades_filtered_by_time',
    'symbol': symbol,
    'count': count,
    'startTime': startTime,
    'endTime': endTime,
    'sequentialId': sequentialId.toString(),
  };
}

/// 마켓 요약 정보 불러오기 이벤트
class MarketSummaryFetchedEvent extends SignalEvent {
  final String symbol;
  
  MarketSummaryFetchedEvent({
    required this.symbol,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'market_summary_fetched',
    'symbol': symbol,
    'sequentialId': sequentialId.toString(),
  };
}

/// 데이터소스 종료 이벤트
class MarketDataSourceDisposedEvent extends SignalEvent {
  MarketDataSourceDisposedEvent() 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'market_data_source_disposed',
    'sequentialId': sequentialId.toString(),
  };
}

/// API 에러 이벤트
class ApiErrorEvent extends SignalEvent {
  final String operation;
  final String message;
  final String? symbol;
  
  ApiErrorEvent({
    required this.operation,
    required this.message,
    this.symbol,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'api_error',
    'operation': operation,
    'message': message,
    'symbol': symbol,
    'sequentialId': sequentialId.toString(),
  };
}

/// API를 통해 실제 시장 데이터를 가져오는 구현체
class RealMarketDataSource implements MarketDataSource {
  final ApiService _apiService;
  final AppLogger _logger;
  final MetricLogger _metricLogger;
  final SignalBus _signalBus;
  
  // 심볼 캐시 - 반복적인 API 호출 방지
  List<String>? _cachedSymbols;
  final Map<String, MarketModel> _cachedMarketPrices = {};
  
  // 캐시 만료 시간 (밀리초)
  static const int _cacheTtl = 60000; // 1분
  final Map<String, int> _cacheTimestamps = {};
  
  RealMarketDataSource({
    required ApiService apiService,
    required AppLogger logger,
    required MetricLogger metricLogger,
    required SignalBus signalBus,
  }) : _apiService = apiService,
       _logger = logger,
       _metricLogger = metricLogger,
       _signalBus = signalBus;
  
  @override
  Future<List<String>> getAllSymbols() async {
    try {
      // 캐시된 값이 있으면 반환
      if (_cachedSymbols != null) {
        _logger.logInfo('Returning cached symbols list (${_cachedSymbols!.length} symbols)');
        return _cachedSymbols!;
      }
      
      // ApiService 사용
      final symbols = await _apiService.fetchAllSymbols();
      _cachedSymbols = symbols;
      _logger.logInfo('Fetched ${symbols.length} symbols from API');
      _metricLogger.incrementCounter('symbols_fetched', labels: {'count': symbols.length.toString()});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(SymbolsFetchedEvent(
        count: symbols.length,
      ));
      
      return symbols;
    } catch (e) {
      _logger.logError('Failed to get all symbols', error: e);
      _metricLogger.incrementCounter('api_errors', labels: {'operation': 'getAllSymbols'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(ApiErrorEvent(
        operation: 'getAllSymbols',
        message: e.toString(),
      ));
      
      throw ServerException(message: 'Failed to get symbols: $e');
    }
  }
  
  @override
  Future<MarketModel> getMarketPrice(String symbol) async {
    try {
      // 캐시 확인
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_cachedMarketPrices.containsKey(symbol)) {
        final timestamp = _cacheTimestamps[symbol] ?? 0;
        if (now - timestamp < _cacheTtl) {
          _logger.logInfo('Returning cached market price for $symbol');
          _metricLogger.incrementCounter('cache_hits', labels: {'type': 'market_price', 'symbol': symbol});
          return _cachedMarketPrices[symbol]!;
        }
      }
      
      // ApiService 사용
      final data = await _apiService.fetchMarketPrice(symbol);
      final marketModel = MarketModel.fromJson(data, _apiService.platform);
      
      // 캐시 업데이트
      _cachedMarketPrices[symbol] = marketModel;
      _cacheTimestamps[symbol] = now;
      
      _logger.logInfo('Fetched market price for $symbol: ${marketModel.currentPrice}');
      _metricLogger.incrementCounter('market_prices_fetched', labels: {'symbol': symbol});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(MarketPriceFetchedEvent(
        symbol: symbol,
        price: marketModel.currentPrice,
      ));
      
      return marketModel;
    } catch (e) {
      _logger.logError('Failed to get market price for $symbol', error: e);
      _metricLogger.incrementCounter('api_errors', labels: {'operation': 'getMarketPrice', 'symbol': symbol});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(ApiErrorEvent(
        operation: 'getMarketPrice',
        message: e.toString(),
        symbol: symbol,
      ));
      
      throw ServerException(message: 'Failed to get market price: $e');
    }
  }
  
  @override
  Future<Map<String, MarketModel>> getMultipleMarketPrices(List<String> symbols) async {
    final result = <String, MarketModel>{};
    final failedSymbols = <String>[];
    
    // 각 심볼에 대해 병렬로 요청 처리
    final futures = symbols.map((symbol) async {
      try {
        final marketPrice = await getMarketPrice(symbol);
        return MapEntry(symbol, marketPrice);
      } catch (e) {
        failedSymbols.add(symbol);
        _logger.logError('Failed to get price for $symbol', error: e);
        return null;
      }
    });
    
    // 모든 요청 완료 대기
    final results = await Future.wait(futures);
    
    // null이 아닌 결과만 맵에 추가
    for (final entry in results) {
      if (entry != null) {
        result[entry.key] = entry.value;
      }
    }
    
    if (failedSymbols.isNotEmpty) {
      _logger.logError('Failed to get prices for ${failedSymbols.length} symbols: $failedSymbols');
    }
    
    _logger.logInfo('Fetched prices for ${result.length}/${symbols.length} symbols');
    _metricLogger.incrementCounter('multiple_market_prices_fetched', 
        labels: {'success': result.length.toString(), 'failed': failedSymbols.length.toString()});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    _signalBus.fire(MultipleMarketPricesFetchedEvent(
      count: result.length,
      failed: failedSymbols.length,
    ));
    
    return result;
  }
  
  @override
  Future<List<TradeModel>> getRecentTrades(String symbol, {int limit = 50}) async {
    try {
      // ApiService 사용
      final data = await _apiService.fetchRecentTrades(symbol, limit: limit);
      
      final trades = data.map((tradeData) {
        // API 응답에 플랫폼 정보 추가
        final tradeJson = Map<String, dynamic>.from(tradeData);
        tradeJson['platform'] = _apiService.platform.toString().split('.').last;
        
        return TradeModel.fromExchangeJson(tradeJson);
      }).toList();
      
      _logger.logInfo('Fetched ${trades.length} recent trades for $symbol');
      _metricLogger.incrementCounter('trades_fetched', labels: {'symbol': symbol, 'count': trades.length.toString()});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(TradesFetchedEvent(
        symbol: symbol,
        count: trades.length,
      ));
      
      return trades;
    } catch (e) {
      _logger.logError('Failed to get recent trades for $symbol', error: e);
      _metricLogger.incrementCounter('api_errors', labels: {'operation': 'getRecentTrades', 'symbol': symbol});
      
      // 객체지향 방식으로 시그널 이벤트 발송  
      _signalBus.fire(ApiErrorEvent(
        operation: 'getRecentTrades',
        message: e.toString(),
        symbol: symbol,
      ));
      
      throw ServerException(message: 'Failed to get recent trades: $e');
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getCandles(String symbol, String interval, {int limit = 100}) async {
    try {
      // ApiService 사용
      final data = await _apiService.fetchCandles(symbol, interval, limit: limit);
      
      // 거래소별 캔들 데이터 구조를 통일된 형식으로 변환
      final formattedCandles = data.map((candleData) {
        final candle = <String, dynamic>{};
        
        switch (_apiService.platform) {
          case ExchangePlatform.upbit:
            candle['timestamp'] = candleData['timestamp'];
            candle['open'] = candleData['opening_price'];
            candle['high'] = candleData['high_price'];
            candle['low'] = candleData['low_price'];
            candle['close'] = candleData['trade_price'];
            candle['volume'] = candleData['candle_acc_trade_volume'];
            break;
          case ExchangePlatform.binance:
            // Binance는 배열 형태로 반환
            candle['timestamp'] = candleData[0];
            candle['open'] = double.parse(candleData[1].toString());
            candle['high'] = double.parse(candleData[2].toString());
            candle['low'] = double.parse(candleData[3].toString());
            candle['close'] = double.parse(candleData[4].toString());
            candle['volume'] = double.parse(candleData[5].toString());
            break;
          case ExchangePlatform.bybit:
            candle['timestamp'] = int.parse(candleData[0]);
            candle['open'] = double.parse(candleData[1]);
            candle['high'] = double.parse(candleData[2]);
            candle['low'] = double.parse(candleData[3]);
            candle['close'] = double.parse(candleData[4]);
            candle['volume'] = double.parse(candleData[5]);
            break;
          case ExchangePlatform.bithumb:
            final timestamp = int.parse(candleData[0].toString());
            candle['timestamp'] = timestamp;
            candle['open'] = double.parse(candleData[1].toString());
            candle['high'] = double.parse(candleData[2].toString());
            candle['low'] = double.parse(candleData[3].toString());
            candle['close'] = double.parse(candleData[4].toString());
            candle['volume'] = double.parse(candleData[5].toString());
            break;
        }
        
        return candle;
      }).toList();
      
      _logger.logInfo('Fetched ${formattedCandles.length} candles for $symbol ($interval)');
      _metricLogger.incrementCounter('candles_fetched', 
          labels: {'symbol': symbol, 'interval': interval, 'count': formattedCandles.length.toString()});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(CandlesFetchedEvent(
        symbol: symbol,
        interval: interval,
        count: formattedCandles.length,
      ));
      
      return formattedCandles;
    } catch (e) {
      _logger.logError('Failed to get candles for $symbol', error: e);
      _metricLogger.incrementCounter('api_errors', 
          labels: {'operation': 'getCandles', 'symbol': symbol, 'interval': interval});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(ApiErrorEvent(
        operation: 'getCandles',
        message: e.toString(),
        symbol: symbol,
      ));
      
      throw ServerException(message: 'Failed to get candles: $e');
    }
  }
  
  @override
  Future<List<TradeModel>> getTradesByVolume(String symbol, double minAmount, {int limit = 50}) async {
    try {
      // 충분한 거래 내역을 가져온 후 필터링
      final allTrades = await getRecentTrades(symbol, limit: limit * 2);
      
      // 거래 금액으로 필터링
      final filteredTrades = allTrades
          .where((trade) => trade.amount >= minAmount)
          .take(limit)
          .toList();
      
      _logger.logInfo('Filtered ${filteredTrades.length} trades by volume (min: $minAmount) for $symbol');
      _metricLogger.incrementCounter('trades_filtered', 
          labels: {'symbol': symbol, 'type': 'volume', 'count': filteredTrades.length.toString()});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(TradesFilteredByVolumeEvent(
        symbol: symbol,
        count: filteredTrades.length,
        minAmount: minAmount,
      ));
      
      return filteredTrades;
    } catch (e) {
      _logger.logError('Failed to get trades by volume for $symbol', error: e);
      _metricLogger.incrementCounter('api_errors', 
          labels: {'operation': 'getTradesByVolume', 'symbol': symbol});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(ApiErrorEvent(
        operation: 'getTradesByVolume',
        message: e.toString(),
        symbol: symbol,
      ));
      
      throw ServerException(message: 'Failed to get trades by volume: $e');
    }
  }
  
  @override
  Future<List<TradeModel>> getTradesByTimeRange(String symbol, int startTime, int endTime) async {
    try {
      // 대부분의 거래소 API는 시간 범위로 직접 필터링하기 어려움
      // 최근 거래 내역을 가져와서 애플리케이션 레벨에서 필터링
      final allTrades = await getRecentTrades(symbol, limit: 100);
      
      final filteredTrades = allTrades
          .where((trade) => 
              trade.timestamp >= startTime && 
              trade.timestamp <= endTime)
          .toList();
      
      _logger.logInfo('Filtered ${filteredTrades.length} trades by time range for $symbol');
      _metricLogger.incrementCounter('trades_filtered', 
          labels: {'symbol': symbol, 'type': 'time_range', 'count': filteredTrades.length.toString()});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(TradesFilteredByTimeEvent(
        symbol: symbol,
        count: filteredTrades.length,
        startTime: startTime,
        endTime: endTime,
      ));
      
      return filteredTrades;
    } catch (e) {
      _logger.logError('Failed to get trades by time range for $symbol', error: e);
      _metricLogger.incrementCounter('api_errors', 
          labels: {'operation': 'getTradesByTimeRange', 'symbol': symbol});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(ApiErrorEvent(
        operation: 'getTradesByTimeRange',
        message: e.toString(),
        symbol: symbol,
      ));
      
      throw ServerException(message: 'Failed to get trades by time range: $e');
    }
  }
  
  @override
  Future<Map<String, dynamic>> getMarketSummary(String symbol) async {
    try {
      // 시장 정보 가져오기
      final marketModel = await getMarketPrice(symbol);
      
      // 24시간 캔들 데이터 가져오기 (일봉)
      final candles = await getCandles(symbol, '1d', limit: 1);
      
      // 결과 맵 구성
      final summary = <String, dynamic>{
        'symbol': symbol,
        'current_price': marketModel.currentPrice,
        'open_price': marketModel.openPrice,
        'high_price': marketModel.highPrice,
        'low_price': marketModel.lowPrice,
        'volume_24h': marketModel.volume24h,
        'price_change_24h': marketModel.priceChange24h,
        'price_change_percentage_24h': marketModel.priceChangePercentage24h,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // 캔들 데이터가 있으면 추가 정보 포함
      if (candles.isNotEmpty) {
        summary['candle_data'] = candles.first;
      }
      
      _logger.logInfo('Fetched market summary for $symbol');
      _metricLogger.incrementCounter('market_summary_fetched', labels: {'symbol': symbol});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(MarketSummaryFetchedEvent(
        symbol: symbol,
      ));
      
      return summary;
    } catch (e) {
      _logger.logError('Failed to get market summary for $symbol', error: e);
      _metricLogger.incrementCounter('api_errors', 
          labels: {'operation': 'getMarketSummary', 'symbol': symbol});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(ApiErrorEvent(
        operation: 'getMarketSummary',
        message: e.toString(),
        symbol: symbol,
      ));
      
      throw ServerException(message: 'Failed to get market summary: $e');
    }
  }

  @override
  Future<bool> isValidSymbol(String symbol) async {
    try {
      final symbols = await getAllSymbols();
      return symbols.contains(symbol);
    } catch (e) {
      _logger.logError('Failed to check if symbol is valid: $symbol', error: e);
      return false;
    }
  }
  
  @override
  void dispose() {
    // 캐시 정리
    _cachedSymbols = null;
    _cachedMarketPrices.clear();
    _cacheTimestamps.clear();
    
    _logger.logInfo('RealMarketDataSource disposed');
    _metricLogger.incrementCounter('data_source_disposals');
    
    // 객체지향 방식으로 시그널 이벤트 발송
    _signalBus.fire(MarketDataSourceDisposedEvent());
  }
}