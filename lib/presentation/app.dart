import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/navigation/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Onbit V2 Triple',
      initialRoute: AppRouter.initialRoute,
      getPages: AppRouter.routes,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}