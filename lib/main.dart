import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/di/injection_container.dart';
import 'package:onbit_v2_triple/core/navigation/app_router.dart';

void main() {
  setupDI();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Onbit V2 Triple',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: AppRouter.main,
      getPages: AppRouter.routes,
    );
  }
}