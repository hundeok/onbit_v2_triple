import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';

/// 네트워크 연결 상태.
enum NetworkStatus {
  connected,      // 인터넷 연결됨 (WiFi, Mobile, Ethernet)
  disconnected,   // 인터넷 연결 끊김
  unknown,        // 초기 또는 알 수 없는 상태
}

/// 네트워크 연결 상태 관리.
/// - [connectivity]: 네트워크 상태 제공자.
/// - [logger]: 로깅.
/// - [metricLogger]: 성능 메트릭.
/// - [signalBus]: 이벤트 브로드캐스트.
/// @throws [NetworkException] 네트워크 상태 확인 실패.
class ConnectivityManager {
  final Connectivity _connectivity;
  final AppLogger _logger;
  final MetricLogger _metricLogger;
  final SignalBus _signalBus;

  final BehaviorSubject<NetworkStatus> _statusSubject;
  StreamSubscription? _connectivitySubscription;
  bool _isInitialized = false;

  /// 네트워크 상태 스트림.
  Stream<NetworkStatus> get statusStream => _statusSubject.stream;

  /// 현재 네트워크 상태.
  NetworkStatus get currentStatus => _statusSubject.value;

  /// 네트워크 연결 여부.
  bool get isConnected => currentStatus == NetworkStatus.connected;

  ConnectivityManager({
    required AppLogger logger,
    required MetricLogger metricLogger,
    required SignalBus signalBus,
    Connectivity? connectivity,
  }) : _logger = logger,
       _metricLogger = metricLogger,
       _signalBus = signalBus,
       _connectivity = connectivity ?? Connectivity(),
       _statusSubject = BehaviorSubject<NetworkStatus>.seeded(NetworkStatus.unknown);

  /// 네트워크 상태 모니터링 초기화.
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.logInfo('ConnectivityManager already initialized');
      return;
    }

    await _checkConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
      _logger.logInfo('Network connectivity changed: $result');
      _metricLogger.incrementCounter('network_state_changes', labels: {'status': result.name});
      _signalBus.fire(NetworkStatusChangedEvent(result));
    });

    _isInitialized = true;
    _logger.logInfo('ConnectivityManager initialized');
    _metricLogger.incrementCounter('connectivity_manager_initializations');
  }

  /// 현재 네트워크 상태 확인.
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      _logger.logInfo('Initial network status: $result');
      _metricLogger.incrementCounter('initial_connectivity_checks', labels: {'status': result.name});
    } catch (e, stackTrace) {
      _logger.logError('Failed to get initial connectivity', error: e, stackTrace: stackTrace);
      _statusSubject.add(NetworkStatus.unknown);
      _metricLogger.incrementCounter('connectivity_errors');
      _signalBus.fireError('Failed to get initial connectivity', error: e);
      throw NetworkException(message: 'Connectivity check failed: $e');
    }
  }

  /// ConnectivityResult를 NetworkStatus로 변환.
  void _updateConnectionStatus(ConnectivityResult result) {
    NetworkStatus newStatus;
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.ethernet:
        newStatus = NetworkStatus.connected;
        break;
      case ConnectivityResult.none:
        newStatus = NetworkStatus.disconnected;
        break;
      default:
        newStatus = NetworkStatus.unknown;
    }

    if (_statusSubject.value != newStatus) {
      _statusSubject.add(newStatus);
      _logger.logInfo('Network status updated: $newStatus');
      _metricLogger.incrementCounter('status_updates', labels: {'status': newStatus.name});
    }
  }

  /// 현재 네트워크 상태 확인 및 갱신.
  /// @returns [NetworkStatus] 현재 상태.
  Future<NetworkStatus> checkStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      _logger.logInfo('Checked network status: $currentStatus');
      _metricLogger.incrementCounter('status_checks', labels: {'status': result.name});
      return currentStatus;
    } catch (e, stackTrace) {
      _logger.logError('Failed to check connectivity', error: e, stackTrace: stackTrace);
      _metricLogger.incrementCounter('connectivity_errors');
      _signalBus.fireError('Failed to check connectivity', error: e);
      _statusSubject.add(NetworkStatus.unknown);
      return NetworkStatus.unknown;
    }
  }

  /// 네트워크 연결 대기.
  /// - [timeout]: 최대 대기 시간 (선택).
  /// @throws [TimeoutException] 타임아웃 발생 시.
  Future<void> waitForConnection({Duration? timeout}) async {
    if (isConnected) {
      _logger.logInfo('Already connected, skipping wait');
      return;
    }

    final completer = Completer<void>();
    StreamSubscription? subscription;
    Timer? timeoutTimer;

    if (timeout != null) {
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          subscription?.cancel();
          final error = TimeoutException('Waiting for network connection timed out');
          _logger.logError('Network connection timeout', error: error);
          _metricLogger.incrementCounter('connection_timeouts');
          _signalBus.fireError('Network connection timeout', error: error);
          completer.completeError(error);
        }
      });
    }

    subscription = statusStream.listen((status) {
      if (status == NetworkStatus.connected && !completer.isCompleted) {
        subscription?.cancel();
        timeoutTimer?.cancel();
        _logger.logInfo('Network connected');
        _metricLogger.incrementCounter('connection_successes');
        completer.complete();
      }
    });

    if (currentStatus == NetworkStatus.connected) {
      subscription.cancel();
      timeoutTimer?.cancel();
      _logger.logInfo('Network already connected');
      completer.complete();
    }

    return completer.future;
  }

  /// 리소스 정리.
  void dispose() {
    _connectivitySubscription?.cancel();
    if (!_statusSubject.isClosed) {
      _statusSubject.close();
    }
    _isInitialized = false;
    _logger.logInfo('ConnectivityManager disposed: subscriptions closed');
    _metricLogger.incrementCounter('connectivity_manager_disposals');
    _signalBus.fire(ConnectivityManagerDisposedEvent());
  }
}

/// SignalBus 이벤트 클래스.
class NetworkStatusChangedEvent {
  final ConnectivityResult result;
  NetworkStatusChangedEvent(this.result);
}

class ConnectivityManagerDisposedEvent {}