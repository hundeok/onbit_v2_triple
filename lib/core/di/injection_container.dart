import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/data/datasources/socket_trade_source.dart';
import 'package:onbit_v2_triple/data/repositories/trade_repository_impl.dart';
import 'package:onbit_v2_triple/domain/repositories/trade_repository.dart';
import 'package:onbit_v2_triple/domain/usecases/get_filtered_trades.dart';

void setupDI() {
  Get.lazyPut<AppLogger>(() => AppLogger(), tag: 'core.logger');
  Get.lazyPut<SocketTradeSource>(() => SocketTradeSource(), tag: 'data.socket_trade_source');
  Get.lazyPut<TradeRepository>(
    () => TradeRepositoryImpl(
      socketTradeSource: Get.find(tag: 'data.socket_trade_source'),
      logger: Get.find(tag: 'core.logger'),
    ),
    tag: 'data.trade_repository',
  );
  Get.lazyPut<GetFilteredTrades>(
    () => GetFilteredTrades(
      repository: Get.find(tag: 'data.trade_repository'),
      logger: Get.find(tag: 'core.logger'),
    ),
    tag: 'usecase.get_filtered_trades',
  );
}