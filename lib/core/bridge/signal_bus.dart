import 'dart:async';
import 'dart:isolate';
import 'package:rxdart/rxdart.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';
import 'package:onbit_v2_triple/core/utils/lru_set.dart';

/// 신호 이벤트 유형.
enum SignalEventType {
  trade,            // 일반 거래
  significantTrade, // 대량 거래 (기준 금액 이상)
  alert,            // 알림
  error,            // 에러
}

/// 이벤트 버스로 전송되는 기본 이벤트 클래스.
abstract class SignalEvent {
  final SignalEventType type;
  final int sequentialId;
  final DateTime timestamp;

  SignalEvent(this.type, this.sequentialId)
      : timestamp = DateTime.now();

  /// 이벤트 고유 ID (중복 방지용).
  String get eventId => '${type.name}_$sequentialId';

  /// 이벤트 데이터를 Map으로 변환 (하위 클래스에서 구현).
  Map<String, dynamic> toMap();

  @override
  String toString() => 'SignalEvent(type: $type, time: $timestamp, data: ${toMap()})';
}

/// 거래 이벤트.
class TradeEvent extends SignalEvent {
  final String symbol;
  final double price;
  final double volume;
  final bool isBuy;

  TradeEvent({
    required this.symbol,
    required this.price,
    required this.volume,
    required this.isBuy,
    required int sequentialId,
  }) : super(SignalEventType.trade, sequentialId);

  @override
  Map<String, dynamic> toMap() => {
    'symbol': symbol,
    'price': price,
    'volume': volume,
    'isBuy': isBuy,
    'sequentialId': sequentialId.toString(),
  };
}

/// 대량 거래 이벤트.
class SignificantTradeEvent extends SignalEvent {
  final String symbol;
  final double price;
  final double volume;
  final double amount;

  SignificantTradeEvent({
    required this.symbol,
    required this.price,
    required this.volume,
    required this.amount,
    required int sequentialId,
  }) : super(SignalEventType.significantTrade, sequentialId);

  @override
  Map<String, dynamic> toMap() => {
    'symbol': symbol,
    'price': price,
    'volume': volume,
    'amount': amount,
    'sequentialId': sequentialId.toString(),
  };
}

/// 알림 이벤트.
class AlertEvent extends SignalEvent {
  final String message;
  final Map<String, dynamic> metadata;

  AlertEvent({
    required this.message,
    this.metadata = const {},
    required int sequentialId,
  }) : super(SignalEventType.alert, sequentialId);

  @override
  Map<String, dynamic> toMap() => {
    'message': message,
    ...metadata,
    'sequentialId': sequentialId.toString(),
  };
}

/// 에러 이벤트.
class ErrorEvent extends SignalEvent {
  final String message;
  final String? errorType;
  final String? stackTrace;

  ErrorEvent({
    required this.message,
    this.errorType,
    this.stackTrace,
    int? sequentialId,
  }) : super(SignalEventType.error, 
        sequentialId ?? DateTime.now().millisecondsSinceEpoch);

  @override
  Map<String, dynamic> toMap() => {
    'message': message,
    if (errorType != null) 'errorType': errorType,
    if (stackTrace != null) 'stackTrace': stackTrace,
    'sequentialId': sequentialId.toString(),
  };
}

/// Isolate에서 실행할 캐시 관리 함수.
void _cacheIsolateFunction(SendPort sendPort) {
  final cache = LruSet<String>(maximumSize: 1000);
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message is List) {
      final id = message[0] as String;
      final responsePort = message[1] as SendPort;
      if (cache.contains(id)) {
        responsePort.send(true);
      } else {
        cache.add(id);
        responsePort.send(false);
      }
    } else if (message == 'clear') {
      cache.clear();
    }
  });
}

/// 이벤트 통신을 위한 시그널 버스.
/// - [logger]: 로깅.
/// - [metricLogger]: 성능 메트릭.
/// - [maxCacheSize]: 중복 이벤트 캐시 크기.
/// - [throttleMs]: 거래 이벤트 스로틀링 간격 (ms).
/// @throws [InvalidInputException] 잘못된 이벤트 데이터.
class SignalBus {
  final AppLogger logger;
  final MetricLogger metricLogger;
  final BehaviorSubject<SignalEvent> _stream;
  final LruSet<String> _eventIdCache;
  final int _maxCacheSize;
  final int _throttleMs;
  Isolate? _cacheIsolate;
  SendPort? _cacheSendPort;
  bool _isDisposed = false;

  /// 메인 이벤트 스트림.
  Stream<SignalEvent> get stream => _stream.stream;

  /// 스로틀링된 거래 이벤트 스트림.
  Stream<SignalEvent> get tradeStream => stream
      .where((e) => e.type == SignalEventType.trade)
      .throttleTime(Duration(milliseconds: _throttleMs));

  /// 대량 거래 이벤트 스트림.
  Stream<SignalEvent> get significantTradeStream => stream
      .where((e) => e.type == SignalEventType.significantTrade);
      
  /// 알림 이벤트 스트림.
  Stream<SignalEvent> get alertStream => stream
      .where((e) => e.type == SignalEventType.alert);
      
  /// 에러 이벤트 스트림.
  Stream<SignalEvent> get errorStream => stream
      .where((e) => e.type == SignalEventType.error);

  SignalBus({
    required this.logger,
    required this.metricLogger,
    int maxCacheSize = 1000,
    int throttleMs = AppConfig.defaultThrottleMs,
  }) : _maxCacheSize = maxCacheSize,
       _throttleMs = throttleMs,
       _stream = BehaviorSubject<SignalEvent>(),
       _eventIdCache = LruSet(maximumSize: maxCacheSize) {
    _initCacheIsolate();
  }

  /// Isolate 초기화.
  Future<void> _initCacheIsolate() async {
    try {
      final receivePort = ReceivePort();
      _cacheIsolate = await Isolate.spawn(_cacheIsolateFunction, receivePort.sendPort);
      _cacheSendPort = await receivePort.first as SendPort;
    } catch (e) {
      logger.logError('Failed to initialize cache isolate', error: e);
      metricLogger.incrementCounter('signal_bus_errors', labels: {'type': 'cache_init'});
    }
  }

  /// 이벤트 발생 (객체지향 방식).
  /// - [event]: 발행할 이벤트 객체.
  /// @throws [InvalidInputException] 잘못된 이벤트 데이터.
  void fire(SignalEvent event) {
    if (_isDisposed || _stream.isClosed) {
      logger.logError('Cannot fire event: SignalBus is disposed');
      metricLogger.incrementCounter('signal_bus_errors', labels: {'type': 'disposed'});
      return;
    }

    final id = event.eventId;

    // 중복 이벤트 체크
    _checkDuplicate(id).then((result) {
      if (result) {
        logger.logInfo('Duplicate event ignored: $id');
        metricLogger.incrementCounter('duplicate_events', labels: {'type': event.type.name});
        return;
      }

      // 이벤트 발행
      _stream.add(event);
      logger.logInfo('Signal fired: $event');
      metricLogger.incrementCounter('events_fired', labels: {'type': event.type.name});

      // 대량 거래 감지 (TradeEvent에만 해당)
      if (event is TradeEvent) {
        final amount = event.price * event.volume;
        if (amount > AppConfig.momentaryThreshold) {
          fire(SignificantTradeEvent(
            symbol: event.symbol,
            price: event.price,
            volume: event.volume,
            amount: amount,
            sequentialId: event.sequentialId,
          ));
        }
      }
    }).catchError((e) {
      logger.logError('Error checking duplicate event: $id', error: e);
      metricLogger.incrementCounter('signal_bus_errors', labels: {'type': 'duplicate_check'});
    });
  }

  /// 기존 코드와의 호환성을 위한 Map 기반 이벤트 발행 메서드.
  /// - [type]: 이벤트 유형.
  /// - [data]: 이벤트 데이터 (sequentialId 필수).
  /// @throws [InvalidInputException] sequentialId 누락 시.
  void fireWithMap(SignalEventType type, Map<String, dynamic> data) {
    if (_isDisposed || _stream.isClosed) {
      logger.logError('Cannot fire event: SignalBus is disposed');
      metricLogger.incrementCounter('signal_bus_errors', labels: {'type': 'disposed'});
      return;
    }

    if (!data.containsKey('sequentialId') && type != SignalEventType.error) {
      logger.logWarning('Missing sequentialId in event data: $data');
      metricLogger.incrementCounter('invalid_events', labels: {'type': type.name});
      throw InvalidInputException(message: 'sequentialId is required');
    }

    // sequentialId 처리
    final sequentialId = data.containsKey('sequentialId')
        ? int.tryParse(data['sequentialId'].toString()) ?? DateTime.now().millisecondsSinceEpoch
        : DateTime.now().millisecondsSinceEpoch;

    // 이벤트 타입에 따른 객체 생성
    SignalEvent event;
    
    if (type == SignalEventType.trade) {
      event = TradeEvent(
        symbol: data['symbol'] as String? ?? 'unknown',
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        volume: (data['volume'] as num?)?.toDouble() ?? 0.0,
        isBuy: data['isBuy'] as bool? ?? false,
        sequentialId: sequentialId,
      );
    } else if (type == SignalEventType.significantTrade) {
      event = SignificantTradeEvent(
        symbol: data['symbol'] as String? ?? 'unknown',
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        volume: (data['volume'] as num?)?.toDouble() ?? 0.0,
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        sequentialId: sequentialId,
      );
    } else if (type == SignalEventType.alert) {
      final metadata = Map<String, dynamic>.from(data);
      metadata.remove('message');
      metadata.remove('sequentialId');
      
      event = AlertEvent(
        message: data['message'] as String? ?? '',
        metadata: metadata,
        sequentialId: sequentialId,
      );
    } else {
      // SignalEventType.error
      event = ErrorEvent(
        message: data['message'] as String? ?? 'Unknown error',
        errorType: data['errorType'] as String?,
        stackTrace: data['stackTrace'] as String?,
        sequentialId: sequentialId,
      );
    }

    // 객체지향 방식으로 이벤트 발행
    fire(event);
  }

  /// 중복 이벤트 체크.
  Future<bool> _checkDuplicate(String id) async {
    if (_cacheSendPort == null) {
      // 로컬 캐시로 대체
      if (_eventIdCache.contains(id)) return true;
      _eventIdCache.add(id);
      return false;
    }
    final receivePort = ReceivePort();
    _cacheSendPort!.send([id, receivePort.sendPort]);
    return await receivePort.first as bool;
  }

  /// 거래 이벤트 발생.
  void fireTrade({
    required String symbol,
    required double price,
    required double volume,
    required bool isBuy,
    required int sequentialId,
  }) {
    fire(TradeEvent(
      symbol: symbol,
      price: price,
      volume: volume,
      isBuy: isBuy,
      sequentialId: sequentialId,
    ));
  }

  /// 알림 이벤트 발생.
  void fireAlert(String message, {
    Map<String, dynamic> metadata = const {},
    required int sequentialId,
  }) {
    fire(AlertEvent(
      message: message,
      metadata: metadata,
      sequentialId: sequentialId,
    ));
  }

  /// 에러 이벤트 발생.
  void fireError(String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    logger.logError(message, error: error, stackTrace: stackTrace);
    fire(ErrorEvent(
      message: message,
      errorType: error?.runtimeType.toString(),
      stackTrace: stackTrace?.toString(),
    ));
  }
  
  /// 리스너 정리 (API Service 호환용).
  void clearListeners() {
    // 호환성을 위해 제공하지만 내부적으로는 아무 동작 안 함
    logger.logInfo('clearListeners called (compatibility method)');
  }

  /// 리소스 해제.
  /// - 스트림 및 캐시 정리.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _stream.close();
    try {
      if (_cacheSendPort != null) {
        _cacheSendPort!.send('clear');
      }
      _cacheIsolate?.kill(priority: Isolate.immediate);
      _eventIdCache.clear();
      logger.logInfo('SignalBus disposed: stream closed, cache cleared');
      metricLogger.incrementCounter('signal_bus_disposals');
    } catch (e) {
      logger.logError('Failed to dispose SignalBus', error: e);
      metricLogger.incrementCounter('signal_bus_errors', labels: {'type': 'dispose'});
    }
  }
}