import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:onbit_v2_triple/core/di/bindings/service_binding.dart';
import 'package:onbit_v2_triple/core/di/bindings/data_source_binding.dart';
import 'package:onbit_v2_triple/core/di/bindings/repository_binding.dart';
import 'package:onbit_v2_triple/core/di/bindings/usecase_binding.dart';
import 'package:onbit_v2_triple/presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Get.put(ServiceBinding());
  Get.put(DataSourceBinding());
  Get.put(RepositoryBinding());
  Get.put(UsecaseBinding());
  runApp(const App());
}