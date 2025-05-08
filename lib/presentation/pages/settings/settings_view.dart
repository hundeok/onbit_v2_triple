import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Exchange Platform',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          DropdownButton<ExchangePlatform>(
            value: AppConfig.defaultPlatform,
            items: ExchangePlatform.values.map((platform) {
              return DropdownMenuItem(
                value: platform,
                child: Text(platform.toString().split('.').last),
              );
            }).toList(),
            onChanged: (value) {
              // TODO: Implement platform change logic
              Get.snackbar('Info', 'Platform change not implemented yet');
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Trade Filters',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ...AppConfig.tradeFilters.map((filter) {
            return ListTile(
              title: Text(AppConfig.filterNames[filter] ?? filter.toString()),
              onTap: () {
                // TODO: Implement filter selection logic
                Get.snackbar('Info', 'Filter selection not implemented yet');
              },
            );
          }),
        ],
      ),
    );
  }
}