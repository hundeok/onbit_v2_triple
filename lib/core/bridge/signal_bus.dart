import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';

/// 신호 이벤트의 유형을 정의하는 열거형
enum SignalEventType {
  trade, // 일반 거래 발생
  significantTrade, // 대량 거래 발생 (기준 금액 이상)
  alert, // 알림
  error, // 에러
}

/// 이벤트 버스로 전송되는 이벤트 데이터 클래스
class SignalEvent {
  final SignalEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  SignalEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// 이벤트의 고유 ID (중복 제거용)
  String get eventId => '${type.name}_${data['sequentialId'] ?? timestamp.microsecondsSinceEpoch}';
  
  @override
  String toString() => 'SignalEvent(type: $type, time: $timestamp, data: $data)';
}

/// 이벤트 통신을 위한 간소화된 시그널 버스
class SignalBus {
  final AppLogger logger;
  
  // 이벤트 스트림
  final BehaviorSubject<SignalEvent> _stream = BehaviorSubject(); // ignore: prefer_const_constructors
  
  // 중복 이벤트 방지를 위한 캐시
  final Set<String> _eventIdCache = {};
  final int _maxCacheSize;
  final int _throttleMs;
  
  // 메인 이벤트 스트림
  Stream<SignalEvent> get stream => _stream.stream;
  
  // 스로틀링된 거래 이벤트 스트림
  Stream<SignalEvent> get tradeStream => stream
      .where((e) => e.type == SignalEventType.trade)
      .throttleTime(Duration(milliseconds: _throttleMs));
  
  // 대량 거래 이벤트 스트림
  Stream<SignalEvent> get significantTradeStream => stream
      .where((e) => e.type == SignalEventType.significantTrade);
  
  SignalBus({
    required this.logger,
    int maxCacheSize = 1000,
    int throttleMs = 100,
  }) : _maxCacheSize = maxCacheSize,
       _throttleMs = throttleMs;
  
  /// 이벤트 발생
  void fire(SignalEventType type, Map<String, dynamic> data) {
    if (_stream.isClosed) {
      logger.logError('Cannot fire event: SignalBus is disposed');
      return;
    }
    
    final event = SignalEvent(type: type, data: Map.from(data));
    final id = event.eventId;
    
    // 중복 이벤트 체크
    if (_eventIdCache.contains(id)) return;
    
    // 이벤트 ID 캐시 관리
    _eventIdCache.add(id);
    if (_eventIdCache.length > _maxCacheSize) {
      _eventIdCache.remove(_eventIdCache.first);
    }
    
    // 이벤트 발행
    _stream.add(event);
    logger.logInfo('Signal fired: $event');
    
    // 대량 거래 감지 (거래 이벤트인 경우)
    if (type == SignalEventType.trade) {
      final volume = (data['volume'] as num?)?.toDouble() ?? 0.0;
      final price = (data['price'] as num?)?.toDouble() ?? 0.0;
      final amount = volume * price;
      
      if (amount > AppConfig.momentaryThreshold) {
        fire(SignalEventType.significantTrade, {
          ...data,
          'amount': amount,
        });
      }
    }
  }
  
  /// 거래 이벤트 발생
  void fireTrade(Map<String, dynamic> data) {
    fire(SignalEventType.trade, data);
  }
  
  /// 알림 이벤트 발생
  void fireAlert(Map<String, dynamic> data) {
    fire(SignalEventType.alert, data);
  }
  
  /// 에러 이벤트 발생
  void fireError(String message, {Object? error, StackTrace? stackTrace}) {
    logger.logError(message, error: error, stackTrace: stackTrace);
    fire(SignalEventType.error, {
      'message': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  /// 리소스 해제
  void dispose() {
    _stream.close();
    _eventIdCache.clear();
    logger.logInfo('SignalBus disposed');
  }
}