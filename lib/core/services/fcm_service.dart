import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/di/tags.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';

/// FCM 관련 SignalBus 이벤트 클래스들
/// FCM 초기화 완료 이벤트
class FcmInitializedEvent extends SignalEvent {
  FcmInitializedEvent() 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'fcm_initialized',
    'sequentialId': sequentialId.toString(),
  };
}

/// FCM 에러 이벤트
class FcmErrorEvent extends SignalEvent {
  final String message;
  
  FcmErrorEvent(this.message) 
      : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'fcm_error',
    'message': message,
    'sequentialId': sequentialId.toString(),
  };
}

/// FCM 알림 수신 이벤트
class FcmNotificationEvent extends SignalEvent {
  final String title;
  final String body;
  
  FcmNotificationEvent(this.title, this.body) 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'fcm_notification',
    'title': title,
    'body': body,
    'sequentialId': sequentialId.toString(),
  };
}

/// FCM 서비스 종료 이벤트
class FcmServiceDisposedEvent extends SignalEvent {
  FcmServiceDisposedEvent() 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'fcm_service_disposed',
    'sequentialId': sequentialId.toString(),
  };
}

/// FCM 상태.
enum FcmState {
  initialized,      // 초기화 완료
  failed,           // 초기화 실패
  permissionDenied, // 권한 거부
}

/// Firebase Cloud Messaging(FCM) 관리 서비스.
/// - 푸시 알림 초기화 및 처리.
/// - [ServiceBinding]에서 DI 주입.
/// @see [FirebaseMessaging] for FCM integration.
class FcmService {
  final FirebaseMessaging _messaging;
  final AppLogger logger;
  final MetricLogger metricLogger;
  final SignalBus signalBus;
  FcmState _fcmState = FcmState.failed;
  StreamSubscription<RemoteMessage>? _messageSubscription;

  FcmState get fcmState => _fcmState;

  FcmService({
    required AppLogger logger,
    required MetricLogger metricLogger,
    required SignalBus signalBus,
    FirebaseMessaging? messaging,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       logger = logger,
       metricLogger = metricLogger,
       signalBus = signalBus;

  /// FCM 초기화.
  /// - 권한 요청, 토큰 획득, 메시지 리스너 설정.
  /// - [AppConfig.isDebugMode]에 따라 로깅 상세도 조정.
  /// @throws [FcmException] 초기화 실패 시.
  Future<void> setupFCM() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        _fcmState = FcmState.permissionDenied;
        final error = FcmException(message: 'FCM permission denied');
        logger.logError(error.message, error: error, metricLogger: metricLogger);
        metricLogger.incrementCounter('fcm_permission_denied');
        
        // 객체지향 방식으로 시그널 이벤트 발송
        signalBus.fire(FcmErrorEvent(error.message));
        
        throw error;
      }

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      _messageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title ?? 'No title';
        final body = message.notification?.body ?? 'No body';
        logger.logInfo(
          'Foreground message: $title - $body',
          metricLogger: metricLogger,
        );
        metricLogger.incrementCounter('fcm_messages_received', labels: {'type': 'foreground'});
        
        // 객체지향 방식으로 시그널 이벤트 발송
        signalBus.fire(FcmNotificationEvent(title, body));
      });

      final token = await _messaging.getToken();
      if (token == null) {
        final error = FcmException(message: 'Failed to retrieve FCM token');
        logger.logError(error.message, error: error, metricLogger: metricLogger);
        metricLogger.incrementCounter('fcm_token_errors');
        
        // 객체지향 방식으로 시그널 이벤트 발송
        signalBus.fire(FcmErrorEvent(error.message));
        
        throw error;
      }

      _fcmState = FcmState.initialized;
      logger.logInfo(
        AppConfig.isDebugMode ? 'FCM Token: $token' : 'FCM Token retrieved',
        metricLogger: metricLogger,
      );
      metricLogger.incrementCounter('fcm_initializations', labels: {'status': 'success'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus.fire(FcmInitializedEvent());
    } catch (e, stackTrace) {
      _fcmState = FcmState.failed;
      final error = FcmException(message: 'FCM setup failed: $e');
      logger.logError(
        error.message,
        error: e,
        stackTrace: stackTrace,
        metricLogger: metricLogger,
      );
      metricLogger.incrementCounter('fcm_initializations', labels: {'status': 'failure'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus.fire(FcmErrorEvent(error.message));
      
      throw error;
    }
  }

  /// 백그라운드 메시지 핸들러.
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    final logger = Get.isRegistered<AppLogger>(tag: DITags.loggerTag)
        ? Get.find<AppLogger>(tag: DITags.loggerTag)
        : AppLogger();
    final metricLogger = Get.isRegistered<MetricLogger>(tag: DITags.metricLoggerTag)
        ? Get.find<MetricLogger>(tag: DITags.metricLoggerTag)
        : null;
    final signalBus = Get.isRegistered<SignalBus>(tag: DITags.signalBusTag)
        ? Get.find<SignalBus>(tag: DITags.signalBusTag)
        : null;

    final title = message.notification?.title ?? 'No title';
    final body = message.notification?.body ?? 'No body';
    logger.logInfo(
      'Background message: $title - $body',
      metricLogger: metricLogger,
    );
    metricLogger?.incrementCounter('fcm_messages_received', labels: {'type': 'background'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(FcmNotificationEvent(title, body));
  }

  /// 푸시 알림 처리.
  /// - [data]: 알림 데이터.
  /// - [platform]: 거래소 플랫폼.
  /// @throws [FcmException] FCM 초기화되지 않았거나 데이터가 유효하지 않을 경우.
  void handleNotification(Map<String, dynamic> data, ExchangePlatform platform) {
    if (_fcmState != FcmState.initialized) {
      final error = FcmException(message: 'FCM not initialized');
      logger.logError(error.message, error: error, metricLogger: metricLogger);
      metricLogger.incrementCounter('fcm_notification_errors', labels: {'reason': 'not_initialized'});
      throw error;
    }

    if (!ExchangePlatform.values.contains(platform)) {
      final error = InvalidInputException(message: 'Invalid platform: $platform');
      logger.logError(error.message, error: error, metricLogger: metricLogger);
      metricLogger.incrementCounter('fcm_notification_errors', labels: {'reason': 'invalid_platform'});
      throw error;
    }

    final title = data['title']?.toString() ?? 'Notification';
    final body = data['body']?.toString() ?? 'No message';
    logger.logInfo(
      'FCM notification: $title - $body (Platform: $platform)',
      metricLogger: metricLogger,
    );
    metricLogger.incrementCounter('fcm_notifications_processed', labels: {'platform': platform.toString()});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus.fire(FcmNotificationEvent(title, body));

    // TODO: 로컬 알림 전송 로직 (flutter_local_notifications 등) 추가 가능
  }

  /// 리소스 정리.
  void dispose() {
    _messageSubscription?.cancel();
    _fcmState = FcmState.failed;
    logger.logInfo('FcmService disposed', metricLogger: metricLogger);
    metricLogger.incrementCounter('fcm_service_disposals');
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus.fire(FcmServiceDisposedEvent());
  }
}

/// FCM 관련 예외.
class FcmException implements Exception {
  final String message;
  final DateTime timestamp;

  FcmException({required this.message}) : timestamp = DateTime.now();

  @override
  String toString() => 'FcmException(timestamp: $timestamp, message: $message)';
}