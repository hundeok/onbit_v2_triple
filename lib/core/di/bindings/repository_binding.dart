import 'package:get/get.dart';
import 'package:onbit_v2_triple/data/repositories/trade_repository_impl.dart';

class RepositoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TradeRepositoryImpl(socketTradeSource: Get.find()));
  }
}