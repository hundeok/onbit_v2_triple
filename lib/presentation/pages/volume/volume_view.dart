import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:onbit_v2_triple/presentation/controllers/volume_controller.dart';

class VolumeView extends StatelessWidget {
  const VolumeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VolumeController>(tag: 'controller.volume');
    final formatter = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volume Data'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(child: Text(controller.errorMessage.value));
        }
        if (controller.volumeData.isEmpty) {
          return const Center(child: Text('No volume data available'));
        }
        return ListView.builder(
          itemCount: controller.volumeData.length,
          itemBuilder: (context, index) {
            final symbol = controller.volumeData.keys.elementAt(index);
            final volume = controller.volumeData[symbol]!;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 4,
              child: ListTile(
                title: Text(
                  symbol,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('거래량: ${formatter.format(volume)}'),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.fetchVolumeData(
            symbol: 'KRW-BTC',
            timeFrame: 1,
          );
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}