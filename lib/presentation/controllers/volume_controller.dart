import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/domain/usecases/get_volume_data.dart';

class VolumeController extends GetxController {
  final GetVolumeData getVolumeData;
  final AppLogger logger;

  final volumeData = <String, double>{}.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  VolumeController({
    required this.getVolumeData,
    required this.logger,
  });

  Future<void> fetchVolumeData({
    required String symbol,
    int? timeFrame,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await getVolumeData(
      symbol: symbol,
      timeFrame: timeFrame,
    );

    result.fold(
      (failure) {
        errorMessage.value = failure.getUIMessage();
        logger.logError('Fetch volume data failed: ${failure.message}');
        Get.snackbar('Error', errorMessage.value);
      },
      (data) {
        volumeData.assignAll(data);
        logger.logInfo('Fetched volume data: ${data[symbol] ?? 0} for $symbol');
      },
    );

    isLoading.value = false;
  }
}