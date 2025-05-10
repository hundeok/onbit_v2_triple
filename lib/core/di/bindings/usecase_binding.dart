import 'package:get/get.dart';
import 'package:onbit_v2_triple/domain/usecases/subscribe_live_trades.dart';

class UsecaseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SubscribeLiveTrades(Get.find()));
  }
}