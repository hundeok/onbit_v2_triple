import 'dart:async';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/socket/socket_service.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/data/models/trade_model.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:rxdart/rxdart.dart';

class SocketTradeSource {
  final SocketService socketService;
  final AppLogger logger;
  
  // 중복 거래 필터링을 위한 캐시
  final Map<String, String> _lastSequentialIds = {};
  
  // 거래 이벤트 스트림 컨트롤러
  // ignore: prefer_const_constructors
  final _tradeController = BehaviorSubject<TradeModel>();
  
  // 필터링 설정
  double _minVolume = AppConfig.defaultMinVolume;
  double _minTotal = AppConfig.defaultMinTotal;
  
  // 거래소 플랫폼
  late final TradePlatform _platform;
  
  // 소켓 스트림 구독
  StreamSubscription? _socketSubscription;
  bool _isListening = false;
  
  SocketTradeSource({
    required this.socketService,
    required this.logger,
  }) {
    _platform = _mapExchangePlatform(AppConfig.defaultPlatform);
  }
  
  /// 지정된 마켓 목록에 대한 거래 스트림을 반환합니다.
  /// 이미 스트림을 구독 중이라면 기존 스트림을 반환합니다.
  Stream<TradeModel> getTradeStream(List<String> markets) {
    if (_isListening) {
      logger.logInfo('Already listening to trade stream');
      return _tradeController.stream;
    }
    
    logger.logInfo('Starting trade stream for markets: $markets');
    socketService.updateMarkets(markets);
    socketService.connect();
    
    _socketSubscription = socketService.stream.listen(
      (data) {
        try {
          // 플랫폼 정보 추가
          data['platform'] = _platform.toString().split('.').last;
          
          // 거래 데이터 파싱
          final trade = TradeModel.fromExchangeJson(data);
          
          // 중복 및 필터 체크
          if (_isDuplicate(trade)) return;
          if (!_passesFilter(trade)) return;
          
          // 이벤트 발행
          _tradeController.add(trade);
        } catch (e) {
          _handleError('Failed to parse trade data', e);
        }
      },
      onError: (error) => _handleError('WebSocket error', error),
      onDone: () => logger.logInfo('Socket stream closed'),
    );
    
    _isListening = true;
    logger.logInfo('Started listening to trade stream');
    return _tradeController.stream;
  }
  
  /// 중복 거래인지 확인합니다.
  bool _isDuplicate(TradeModel trade) {
    final key = '${trade.platform}_${trade.symbol}';
    if (_lastSequentialIds[key] == trade.sequentialId) {
      return true;
    }
    
    _lastSequentialIds[key] = trade.sequentialId;
    
    // 캐시 크기 제한 (메모리 관리)
    if (_lastSequentialIds.length > 1000) {
      // 가장 오래된 항목 제거
      final oldestKey = _lastSequentialIds.keys.first;
      _lastSequentialIds.remove(oldestKey);
    }
    
    return false;
  }
  
  /// 필터 조건을 통과하는지 확인합니다.
  bool _passesFilter(TradeModel trade) {
    return trade.volume >= _minVolume && trade.amount >= _minTotal;
  }
  
  /// 에러를 처리합니다.
  void _handleError(String context, Object? error) {
    logger.logError(context, error: error);
    
    // 주요 에러만 스트림에 전달
    if (error != null) {
      if (error is SocketException || error is DataParsingException) {
        _tradeController.addError(error);
      } else {
        _tradeController.addError(SocketException(message: context, error: error));
      }
    } else {
      // error가 null인 경우
      _tradeController.addError(SocketException(message: context));
    }
  }
  
  /// 최소 거래량 설정을 업데이트합니다.
  void setMinVolume(double volume) {
    _minVolume = volume;
    logger.logInfo('Updated minimum volume filter: $_minVolume');
  }
  
  /// 최소 거래 금액 설정을 업데이트합니다.
  void setMinTotal(double total) {
    _minTotal = total;
    logger.logInfo('Updated minimum total filter: $_minTotal');
  }
  
  /// 거래소 플랫폼을 설정합니다.
  void setPlatform(TradePlatform platform) {
    _platform = platform;
    logger.logInfo('Updated platform to: $_platform');
  }
  
  /// WebSocket 연결을 종료합니다.
  void disconnect() {
    _socketSubscription?.cancel();
    socketService.disconnect();
    _isListening = false;
    logger.logInfo('Disconnected from trade stream');
  }
  
  /// 모든 리소스를 해제합니다.
  void dispose() {
    disconnect();
    if (!_tradeController.isClosed) {
      _tradeController.close();
    }
    _lastSequentialIds.clear();
    logger.logInfo('Disposed SocketTradeSource');
  }
  
  /// ExchangePlatform을 TradePlatform으로 변환합니다.
  TradePlatform _mapExchangePlatform(ExchangePlatform platform) {
    switch (platform) {
      case ExchangePlatform.upbit:
        return TradePlatform.upbit;
      case ExchangePlatform.binance:
        return TradePlatform.binance;
      case ExchangePlatform.bybit:
        return TradePlatform.bybit;
      case ExchangePlatform.bithumb:
        return TradePlatform.bithumb;
    }
  }
}