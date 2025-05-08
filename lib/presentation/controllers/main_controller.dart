import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/presentation/controllers/trade_controller.dart';
import 'package:onbit_v2_triple/presentation/controllers/momentary_controller.dart';
import 'package:onbit_v2_triple/presentation/controllers/surge_controller.dart';
import 'package:onbit_v2_triple/presentation/controllers/volume_controller.dart';

class MainController extends GetxController {
  final currentIndex = 0.obs;
  final AppLogger logger;

  MainController({required this.logger});

  void changePage(int index) {
    if (currentIndex.value != index) {
      currentIndex.value = index;
      logger.logInfo('Page changed to index: $index');
      _initializePageController(index);
    }
  }

  void _initializePageController(int index) {
    switch (index) {
      case 0: // TradeView
        Get.find<TradeController>(tag: 'controller.trade').fetchFilteredTrades(
          symbol: 'KRW-BTC',
          minPrice: 40000.0,
          maxPrice: 60000.0,
          minVolume: 0.5,
          minTotal: 40000.0,
        );
        break;
      case 1: // MomentaryView
        Get.find<MomentaryController>(tag: 'controller.momentary').fetchMomentaryTrades(
          symbol: 'KRW-BTC',
          minAmount: 500000.0,
          threshold: 2000000.0,
        );
        break;
      case 2: // SurgeView
        Get.find<SurgeController>(tag: 'controller.surge').fetchSurgeTrades(
          symbol: 'KRW-BTC',
          surgeThreshold: 1.1,
          timeWindow: const Duration(minutes: 1),
        );
        break;
      case 3: // VolumeView
        Get.find<VolumeController>(tag: 'controller.volume').fetchVolumeData(
          symbol: 'KRW-BTC',
          timeFrame: 1,
        );
        break;
      default:
        break;
    }
  }
}