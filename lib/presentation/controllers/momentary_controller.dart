import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:onbit_v2_triple/domain/usecases/get_momentary_trades.dart';

class MomentaryController extends GetxController {
  final GetMomentaryTrades getMomentaryTrades;
  final AppLogger logger;

  final trades = <Trade>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  MomentaryController({
    required this.getMomentaryTrades,
    required this.logger,
  });

  Future<void> fetchMomentaryTrades({
    required String symbol,
    double? minAmount,
    double? threshold,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await getMomentaryTrades(
      symbol: symbol,
      minAmount: minAmount,
      threshold: threshold,
    );

    result.fold(
      (failure) {
        errorMessage.value = failure.getUIMessage();
        logger.logError('Fetch momentary trades failed: ${failure.message}');
        Get.snackbar('Error', errorMessage.value);
      },
      (data) {
        trades.assignAll(data);
        logger.logInfo('Fetched ${data.length} momentary trades for $symbol');
      },
    );

    isLoading.value = false;
  }
}