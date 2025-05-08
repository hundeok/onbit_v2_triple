import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:onbit_v2_triple/presentation/controllers/trade_controller.dart';

class TradeCardWidget extends StatelessWidget {
  final Trade trade;

  const TradeCardWidget({super.key, required this.trade});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TradeController>(tag: 'controller.trade');
    final formatter = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');

    return Obx(() => Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 4,
          child: ListTile(
            title: Text(
              trade.symbol,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('가격: ${formatter.format(trade.price)}'),
                Text('거래량: ${trade.volume.toStringAsFixed(2)}'),
                Text('시간: ${DateTime.fromMillisecondsSinceEpoch(trade.timestamp).toString()}'),
                Text(trade.isBuy ? '매수' : '매도'),
              ],
            ),
            trailing: controller.isLoading.value
                ? const CircularProgressIndicator()
                : Icon(trade.isBuy ? Icons.arrow_upward : Icons.arrow_downward),
          ),
        ));
  }
}