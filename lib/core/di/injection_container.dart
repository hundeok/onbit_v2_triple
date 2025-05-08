import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/data/datasources/socket_trade_source.dart';
import 'package:onbit_v2_triple/data/repositories/trade_repository_impl.dart';
import 'package:onbit_v2_triple/domain/repositories/trade_repository.dart';
import 'package:onbit_v2_triple/domain/usecases/get_filtered_trades.dart';
import 'package:onbit_v2_triple/domain/usecases/get_momentary_trades.dart';
import 'package:onbit_v2_triple/domain/usecases/get_surge_trades.dart';
import 'package:onbit_v2_triple/domain/usecases/get_volume_data.dart';
import 'package:onbit_v2_triple/presentation/controllers/main_controller.dart';
import 'package:onbit_v2_triple/presentation/controllers/trade_controller.dart';
import 'package:onbit_v2_triple/presentation/controllers/momentary_controller.dart';
import 'package:onbit_v2_triple/presentation/controllers/surge_controller.dart';
import 'package:onbit_v2_triple/presentation/controllers/volume_controller.dart';

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
  Get.lazyPut<GetMomentaryTrades>(
    () => GetMomentaryTrades(
      repository: Get.find(tag: 'data.trade_repository'),
      logger: Get.find(tag: 'core.logger'),
    ),
    tag: 'usecase.get_momentary_trades',
  );
  Get.lazyPut<GetSurgeTrades>(
    () => GetSurgeTrades(
      repository: Get.find(tag: 'data.trade_repository'),
      logger: Get.find(tag: 'core.logger'),
    ),
    tag: 'usecase.get_surge_trades',
  );
  Get.lazyPut<GetVolumeData>(
    () => GetVolumeData(
      repository: Get.find(tag: 'data.trade_repository'),
      logger: Get.find(tag: 'core.logger'),
    ),
    tag: 'usecase.get_volume_data',
  );
  Get.lazyPut<TradeController>(
    () => TradeController(
      getFilteredTrades: Get.find(tag: 'usecase.get_filtered_trades'),
      logger: Get.find(tag: 'core.logger'),
    ),
    tag: 'controller.trade',
  );
  Get.lazyPut<MomentaryController>(
    () => MomentaryController(
      getMomentaryTrades: Get.find(tag: 'usecase.get_momentary_trades'),
      logger: Get.find(tag: 'core.logger'),
    ),
    tag: 'controller.momentary',
  );
  Get.lazyPut<SurgeController>(
    () => SurgeController(
      getSurgeTrades: Get.find(tag: 'usecase.get_surge_trades'),
      logger: Get.find(tag: 'core.logger'),
    ),
    tag: 'controller.surge',
  );
  Get.lazyPut<VolumeController>(
    () => VolumeController(
      getVolumeData: Get.find(tag: 'usecase.get_volume_data'),
      logger: Get.find(tag: 'core.logger'),
    ),
    tag: 'controller.volume',
  );
  Get.lazyPut<MainController>(
    () => MainController(
      logger: Get.find(tag: 'core.logger'),
    ),
    tag: 'controller.main',
  );
}