import 'package:get/get.dart';
import 'package:onbit_v2_triple/presentation/pages/splash/splash_view.dart';

class AppRouter {
  static const String initialRoute = '/splash';

  static final List<GetPage> routes = [
    GetPage(
      name: '/splash',
      page: () => const SplashView(),
    ),
  ];
}