import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onbit_v2_triple/presentation/controllers/main_controller.dart';
import 'package:onbit_v2_triple/presentation/pages/trade/trade_view.dart';
import 'package:onbit_v2_triple/presentation/pages/momentary/momentary_view.dart';
import 'package:onbit_v2_triple/presentation/pages/surge/surge_view.dart';
import 'package:onbit_v2_triple/presentation/pages/volume/volume_view.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainController>();
    final pages = [
      const TradeView(),
      const MomentaryView(),
      const SurgeView(),
      const VolumeView(),
    ];

    return Obx(() => Scaffold(
          body: pages[controller.currentIndex.value],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changePage,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.trending_up),
                label: 'Trades',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.flash_on),
                label: 'Momentary',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.rocket_launch),
                label: 'Surge',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Volume',
              ),
            ],
          ),
        ));
  }
}