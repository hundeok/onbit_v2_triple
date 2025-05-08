import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:onbit_v2_triple/domain/usecases/get_surge_trades.dart';

class SurgeController extends GetxController {
  final GetSurgeTrades getSurgeTrades;
  final AppLogger logger;

  final trades = <Trade>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  SurgeController({
    required this.getSurgeTrades,
    required this.logger,
  });

  Future<void> fetchSurgeTrades({
    required String symbol,
    double? surgeThreshold,
    Duration? timeWindow,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await getSurgeTrades(
      symbol: symbol,
      surgeThreshold: surgeThreshold,
      timeWindow: timeWindow,
    );

    result.fold(
      (failure) {
        errorMessage.value = failure.getUIMessage();
        logger.logError('Fetch surge trades failed: ${failure.message}');
        Get.snackbar('Error', errorMessage.value);
      },
      (data) {
        trades.assignAll(data);
        logger.logInfo('Fetched ${data.length} surge trades for $symbol');
      },
    );

    isLoading.value = false;
  }
}