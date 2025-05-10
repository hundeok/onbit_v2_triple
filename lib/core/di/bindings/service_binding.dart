import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/core/services/data_service.dart';
import 'package:onbit_v2_triple/core/services/fcm_service.dart';
import 'package:onbit_v2_triple/core/socket/socket_service.dart';

class ServiceBinding extends Bindings {
  static const _prefix = 'service.';
  static const loggerTag = '${_prefix}logger';
  static const signalBusTag = '${_prefix}signal_bus';
  static const socketServiceTag = '${_prefix}socket';
  static const dataServiceTag = '${_prefix}data';
  static const fcmServiceTag = '${_prefix}fcm';

  @override
  void dependencies() {
    _registerLogger();
    _registerSignalBus();
    _registerSocketService();
    _registerDataService();
    _registerFcmService();
  }

  void _registerLogger() {
    Get.putAsync<AppLogger>(
      () async {
        final logger = AppLogger();
        logger.logInfo('AppLogger initialized');
        return logger;
      },
      tag: loggerTag,
      permanent: true,
    );
  }

  void _registerSignalBus() {
    Get.putAsync<SignalBus>(
      () async {
        final logger = await _get<AppLogger>(loggerTag);
        final bus = SignalBus(logger: logger);
        logger.logInfo('SignalBus initialized');
        return bus;
      },
      tag: signalBusTag,
      permanent: true,
    );
  }

  void _registerSocketService() {
    Get.putAsync<SocketService>(
      () async {
        final logger = await _get<AppLogger>(loggerTag);
        final bus = await _get<SignalBus>(signalBusTag);
        final socket = SocketService(
          logger: logger,
          signalBus: bus,
          initialMarkets: const ['KRW-BTC', 'KRW-ETH'],
        );
        logger.logInfo('SocketService initialized');
        return socket;
      },
      tag: socketServiceTag,
    );
  }

  void _registerDataService() {
    Get.putAsync<DataService>(
      () async {
        final logger = await _get<AppLogger>(loggerTag);
        final socket = await _get<SocketService>(socketServiceTag);
        final bus = await _get<SignalBus>(signalBusTag);
        final data = DataService(socketService: socket, signalBus: bus);
        logger.logInfo('DataService initialized');
        return data;
      },
      tag: dataServiceTag,
    );
  }

  void _registerFcmService() {
    Get.putAsync<FcmService>(
      () async {
        final logger = await _get<AppLogger>(loggerTag);
        final fcm = FcmService(logger: logger);
        try {
          await fcm.setupFCM();
          logger.logInfo('FCM initialized');
        } catch (e) {
          logger.logError('FCM init failed', error: e);
        }
        return fcm;
      },
      tag: fcmServiceTag,
    );
  }

  Future<T> _get<T>(String tag) async {
    if (Get.isRegistered<T>(tag: tag)) {
      return Get.find<T>(tag: tag);
    }
    throw Exception('Service $T with tag $tag not registered');
  }

  static Future<void> initializeAll() async {
    final binding = ServiceBinding();
    binding.dependencies();
    await Future.wait([
      Get.putAsync(() async => Get.find<AppLogger>(tag: loggerTag)),
      Get.putAsync(() async => Get.find<SignalBus>(tag: signalBusTag)),
      Get.putAsync(() async => Get.find<SocketService>(tag: socketServiceTag)),
    ]);
    Get.find<AppLogger>(tag: loggerTag)
        .logInfo('All core services initialized ✅');
  }
}
