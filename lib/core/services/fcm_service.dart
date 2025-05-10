import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';

enum FcmState {
  initialized,
  failed,
  permissionDenied,
}

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final AppLogger _logger;
  FcmState _fcmState = FcmState.initialized;

  FcmState get fcmState => _fcmState;

  FcmService({required AppLogger logger}) : _logger = logger;

  Future<void> setupFCM() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        _fcmState = FcmState.permissionDenied;
        _logger.logError('FCM permission denied');
        return;
      }

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _logger.logInfo('Foreground message: ${message.notification?.title}');
      });

      String? token = await _messaging.getToken();
      _logger.logInfo('FCM Token: $token');
      _fcmState = FcmState.initialized;
    } catch (e) {
      _fcmState = FcmState.failed;
      _logger.logError('FCM Setup Failed: $e');
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    AppLogger().logInfo('Background message: ${message.notification?.title}');
  }

  void handleNotification(Map<String, dynamic> data, ExchangePlatform platform) {
    if (_fcmState != FcmState.initialized) {
      _logger.logError('FCM not initialized, skipping notification');
      return;
    }
    final title = data['title'] ?? 'Notification';
    final body = data['body'] ?? 'No message';
    _logger.logInfo('FCM notification: $title - $body (Platform: $platform)');
    // TODO: 실제 푸시 알림 전송 로직 추가
  }

  void dispose() {
    _fcmState = FcmState.failed;
  }
}