import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:rxdart/rxdart.dart';

/// 네트워크 연결 상태를 나타내는 열거형
enum NetworkStatus {
  connected,      // 인터넷 연결됨
  disconnected,   // 인터넷 연결 끊김
  unknown,        // 초기 상태 또는 알 수 없는 상태
}

/// 네트워크 연결 상태를 관리하는 클래스
class ConnectivityManager {
  final Connectivity _connectivity;
  final AppLogger _logger;
  
  // 네트워크 상태 스트림
  // ignore: prefer_const_constructors
  final BehaviorSubject<NetworkStatus> _statusSubject = BehaviorSubject.seeded(NetworkStatus.unknown);
  
  StreamSubscription? _connectivitySubscription;
  bool _isInitialized = false;
  
  /// 현재 네트워크 상태를 반환하는 스트림
  Stream<NetworkStatus> get statusStream => _statusSubject.stream;
  
  /// 현재 네트워크 상태
  NetworkStatus get currentStatus => _statusSubject.value;
  
  /// 현재 네트워크 연결 여부
  bool get isConnected => currentStatus == NetworkStatus.connected;
  
  ConnectivityManager({
    required AppLogger logger,
    Connectivity? connectivity,
  }) : _logger = logger,
       _connectivity = connectivity ?? Connectivity();
  
  /// 네트워크 상태 모니터링 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // 초기 연결 상태 확인
    await _checkConnectivity();
    
    // 연결 상태 변화 감지
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
      _logger.logInfo('Network connectivity changed: $result');
    });
    
    _isInitialized = true;
    _logger.logInfo('ConnectivityManager initialized');
  }
  
  /// 현재 연결 상태 확인
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      _logger.logInfo('Initial network status: $result');
    } catch (e) {
      _logger.logError('Failed to get connectivity', error: e);
      _statusSubject.add(NetworkStatus.unknown);
    }
  }
  
  /// ConnectivityResult에서 NetworkStatus로 변환
  void _updateConnectionStatus(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.ethernet:
        _statusSubject.add(NetworkStatus.connected);
        break;
      case ConnectivityResult.none:
        _statusSubject.add(NetworkStatus.disconnected);
        break;
      default:
        _statusSubject.add(NetworkStatus.unknown);
    }
  }
  
  /// 현재 네트워크 상태 확인 후 갱신
  Future<NetworkStatus> checkStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      return currentStatus;
    } catch (e) {
      _logger.logError('Failed to check connectivity', error: e);
      return NetworkStatus.unknown;
    }
  }
  
  /// 인터넷 연결이 될 때까지 기다리는 메서드
  Future<void> waitForConnection({Duration? timeout}) async {
    if (isConnected) return;
    
    final completer = Completer<void>();
    StreamSubscription? subscription;
    Timer? timeoutTimer;
    
    // 타임아웃 설정
    if (timeout != null) {
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          subscription?.cancel();
          completer.completeError(TimeoutException('Waiting for network connection timed out'));
        }
      });
    }
    
    // 네트워크 상태 변화 감지
    subscription = statusStream.listen((status) {
      if (status == NetworkStatus.connected && !completer.isCompleted) {
        subscription?.cancel();
        timeoutTimer?.cancel();
        completer.complete();
      }
    });
    
    // 현재 상태가 이미 연결됨이면 즉시 완료
    if (currentStatus == NetworkStatus.connected) {
      subscription.cancel();
      timeoutTimer?.cancel();
      completer.complete();
    }
    
    return completer.future;
  }
  
  /// 리소스 해제
  void dispose() {
    _connectivitySubscription?.cancel();
    if (!_statusSubject.isClosed) {
      _statusSubject.close();
    }
    _isInitialized = false;
    _logger.logInfo('ConnectivityManager disposed');
  }
}