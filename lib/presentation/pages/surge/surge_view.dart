import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onbit_v2_triple/presentation/controllers/surge_controller.dart';
import 'package:onbit_v2_triple/presentation/widgets/trade_card_widget.dart';

class SurgeView extends StatelessWidget {
  const SurgeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SurgeController>(tag: 'controller.surge');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Surge Trades'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(child: Text(controller.errorMessage.value));
        }
        if (controller.trades.isEmpty) {
          return const Center(child: Text('No surge trades available'));
        }
        return ListView.builder(
          itemCount: controller.trades.length,
          itemBuilder: (context, index) {
            return TradeCardWidget(trade: controller.trades[index]);
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.fetchSurgeTrades(
            symbol: 'KRW-BTC',
            surgeThreshold: 1.1,
            timeWindow: const Duration(minutes: 1),
          );
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}