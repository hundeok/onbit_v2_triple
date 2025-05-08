import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final logger = Get.find<AppLogger>(tag: 'core.logger');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Notifications not implemented yet',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                logger.logInfo('Test notification triggered');
                Get.snackbar('Notification', 'Test notification logged');
              },
              child: const Text('Test Notification'),
            ),
          ],
        ),
      ),
    );
  }
}