import 'package:get/get.dart';
import 'package:onbit_v2_triple/presentation/pages/main/main_view.dart';
import 'package:onbit_v2_triple/presentation/pages/trade/trade_view.dart';
import 'package:onbit_v2_triple/presentation/pages/momentary/momentary_view.dart';
import 'package:onbit_v2_triple/presentation/pages/surge/surge_view.dart';
import 'package:onbit_v2_triple/presentation/pages/volume/volume_view.dart';
import 'package:onbit_v2_triple/presentation/pages/settings/settings_view.dart';
import 'package:onbit_v2_triple/presentation/pages/notifications/notifications_view.dart';

class AppRouter {
  static const String main = '/';
  static const String trade = '/trade';
  static const String momentary = '/momentary';
  static const String surge = '/surge';
  static const String volume = '/volume';
  static const String settings = '/settings';
  static const String notifications = '/notifications';

  static List<GetPage> routes = [
    GetPage(name: main, page: () => const MainView()),
    GetPage(name: trade, page: () => const TradeView()),
    GetPage(name: momentary, page: () => const MomentaryView()),
    GetPage(name: surge, page: () => const SurgeView()),
    GetPage(name: volume, page: () => const VolumeView()),
    GetPage(name: settings, page: () => const SettingsView()),
    GetPage(name: notifications, page: () => const NotificationsView()),
  ];
}