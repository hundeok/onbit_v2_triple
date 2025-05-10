import 'package:dartz/dartz.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/error/failure.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/data/sources/socket/socket_trade_source.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:onbit_v2_triple/domain/repositories/trade_repository.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

class TradeRepositoryImpl implements TradeRepository {
  final SocketTradeSource socketTradeSource;
  final AppLogger? logger;
  
  // 트레이드 캐시 - 최근 N개 트레이드를 메모리에 유지
  final List<Trade> _recentTrades = [];
  final int _maxCacheSize = 1000;
  
  // 필터 설정
  List<String> _activeMarkets = [];
  double _minAmount = 0.0;
  bool _filterBuys = false;
  bool _filterSells = false;
  
  // 스트림 컨트롤러
  final _tradeStreamController = BehaviorSubject<Either<Failure, Trade>>();
  
  // 구독 관리
  StreamSubscription? _sourceSubscription;
  bool _isSubscribed = false;
  
  TradeRepositoryImpl({
    required this.socketTradeSource,
    this.logger,
  });
  
  @override
  Stream<Either<Failure, Trade>> subscribeLiveTrades(List<String> markets) {
    // 시장이 변경되었거나 아직 구독하지 않았다면 새로 구독
    if (!_isSubscribed || !_areMarketsEqual(markets, _activeMarkets)) {
      _unsubscribe();
      _activeMarkets = List.from(markets);
      _subscribeToSource(markets);
    }
    
    return _tradeStreamController.stream;
  }
  
  void _subscribeToSource(List<String> markets) {
    _sourceSubscription = socketTradeSource.getTradeStream(markets)
      .listen(
        (trade) {
          // 필터 적용
          if (!_passesFilters(trade)) {
            return;
          }
          
          // 캐시에 추가
          _addToCache(trade);
          
          // 스트림에 전달
          _tradeStreamController.add(Right(trade));
        },
        onError: (error) {
          logger?.logError('Error from trade source', error: error);
          
          if (error is SocketException) {
            _tradeStreamController.add(Left(SocketFailure(
              message: error.message, 
              error: error
            )));
          } else if (error is DataParsingException) {
            _tradeStreamController.add(Left(ServerFailure(
              message: error.message, 
              error: error
            )));
          } else {
            _tradeStreamController.add(Left(ServerFailure(
              message: 'Unknown error: $error', 
              error: error
            )));
          }
        },
        onDone: () {
          logger?.logInfo('Trade source stream closed');
          _isSubscribed = false;
        },
      );
    
    _isSubscribed = true;
    logger?.logInfo('Subscribed to trade source for markets: $markets');
  }
  
  void _unsubscribe() {
    _sourceSubscription?.cancel();
    _isSubscribed = false;
    logger?.logInfo('Unsubscribed from trade source');
  }
  
  /// 거래를 캐시에 추가
  void _addToCache(Trade trade) {
    _recentTrades.add(trade);
    
    // 캐시 크기 제한
    if (_recentTrades.length > _maxCacheSize) {
      _recentTrades.removeAt(0);
    }
  }
  
  /// 필터 조건 확인
  bool _passesFilters(Trade trade) {
    // 마켓 필터
    if (_activeMarkets.isNotEmpty && !_activeMarkets.contains(trade.symbol)) {
      return false;
    }
    
    // 금액 필터
    if (_minAmount > 0 && trade.amount < _minAmount) {
      return false;
    }
    
    // 매수/매도 필터
    if (_filterBuys && trade.isBuy) {
      return false;
    }
    
    if (_filterSells && !trade.isBuy) {
      return false;
    }
    
    return true;
  }
  
  /// 마켓 목록 비교
  bool _areMarketsEqual(List<String> markets1, List<String> markets2) {
    if (markets1.length != markets2.length) {
      return false;
    }
    
    final sortedMarkets1 = List<String>.from(markets1)..sort();
    final sortedMarkets2 = List<String>.from(markets2)..sort();
    
    for (var i = 0; i < sortedMarkets1.length; i++) {
      if (sortedMarkets1[i] != sortedMarkets2[i]) {
        return false;
      }
    }
    
    return true;
  }
  
  /// 최소 거래 금액 필터 설정
  void setMinAmountFilter(double amount) {
    _minAmount = amount;
    logger?.logInfo('Set min amount filter: $_minAmount');
  }
  
  /// 매수/매도 필터 설정
  void setDirectionFilter({bool filterBuys = false, bool filterSells = false}) {
    _filterBuys = filterBuys;
    _filterSells = filterSells;
    logger?.logInfo('Set direction filter - filterBuys: $_filterBuys, filterSells: $_filterSells');
  }
  
  /// 최근 N개 거래 가져오기
  List<Trade> getRecentTrades({int limit = 50}) {
    final end = _recentTrades.length;
    final start = end - limit < 0 ? 0 : end - limit;
    return _recentTrades.sublist(start, end).reversed.toList();
  }
  
  /// 특정 마켓의 최근 거래 가져오기
  List<Trade> getRecentTradesByMarket(String market, {int limit = 50}) {
    final trades = _recentTrades
        .where((trade) => trade.symbol == market)
        .toList();
    
    final end = trades.length;
    final start = end - limit < 0 ? 0 : end - limit;
    return trades.sublist(start, end).reversed.toList();
  }
  
  /// 마켓별 집계된 거래량 가져오기
  Map<String, double> getVolumeByMarket() {
    final result = <String, double>{};
    
    for (final trade in _recentTrades) {
      final market = trade.symbol;
      result[market] = (result[market] ?? 0) + trade.volume;
    }
    
    return result;
  }
  
  /// 리소스 정리
  void dispose() {
    _unsubscribe();
    _tradeStreamController.close();
    _recentTrades.clear();
    logger?.logInfo('Disposed TradeRepositoryImpl');
  }
}