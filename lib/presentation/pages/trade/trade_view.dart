import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onbit_v2_triple/presentation/controllers/trade_controller.dart';
import 'package:onbit_v2_triple/presentation/widgets/trade_card_widget.dart';

class TradeView extends StatelessWidget {
  const TradeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TradeController>(tag: 'controller.trade');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade View'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(child: Text(controller.errorMessage.value));
        }
        if (controller.trades.isEmpty) {
          return const Center(child: Text('No trades available'));
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
          controller.fetchFilteredTrades(
            symbol: 'KRW-BTC',
            minPrice: 40000.0,
            maxPrice: 60000.0,
            minVolume: 0.5,
            minTotal: 40000.0,
          );
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}