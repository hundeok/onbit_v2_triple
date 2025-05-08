import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onbit_v2_triple/presentation/controllers/momentary_controller.dart';
import 'package:onbit_v2_triple/presentation/widgets/trade_card_widget.dart';

class MomentaryView extends StatelessWidget {
  const MomentaryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MomentaryController>(tag: 'controller.momentary');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Momentary Trades'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(child: Text(controller.errorMessage.value));
        }
        if (controller.trades.isEmpty) {
          return const Center(child: Text('No momentary trades available'));
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
          controller.fetchMomentaryTrades(
            symbol: 'KRW-BTC',
            minAmount: 500000.0,
            threshold: 2000000.0,
          );
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}