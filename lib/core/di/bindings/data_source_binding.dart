import 'package:get/get.dart';
import 'package:onbit_v2_triple/data/sources/socket/socket_trade_source.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';

class DataSourceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SocketTradeSource(
      socketService: Get.find(),
      logger: Get.find<AppLogger>(),
    ));
  }
}