import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:onbit_v2_triple/domain/usecases/get_filtered_trades.dart';

class TradeController extends GetxController {
  final GetFilteredTrades getFilteredTrades;
  final AppLogger logger;

  final trades = <Trade>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  TradeController({
    required this.getFilteredTrades,
    required this.logger,
  });

  Future<void> fetchFilteredTrades({
    required String symbol,
    double? minPrice,
    double? maxPrice,
    double? minVolume,
    double? minTotal,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await getFilteredTrades(
      symbol: symbol,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minVolume: minVolume,
      minTotal: minTotal,
    );

    result.fold(
      (failure) {
        errorMessage.value = failure.getUIMessage();
        logger.logError('Fetch trades failed: ${failure.message}');
        Get.snackbar('Error', errorMessage.value);
      },
      (data) {
        trades.assignAll(data);
        logger.logInfo('Fetched ${data.length} trades for $symbol');
      },
    );

    isLoading.value = false;
  }
}