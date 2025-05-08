import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/navigation/app_router.dart';
import 'package:onbit_v2_triple/presentation/pages/main/main_view.dart';
import 'package:onbit_v2_triple/presentation/pages/trade/trade_view.dart';
import 'package:onbit_v2_triple/presentation/pages/momentary/momentary_view.dart';
import 'package:onbit_v2_triple/presentation/pages/surge/surge_view.dart';
import 'package:onbit_v2_triple/presentation/pages/volume/volume_view.dart';
import 'package:onbit_v2_triple/presentation/pages/settings/settings_view.dart';
import 'package:onbit_v2_triple/presentation/pages/notifications/notifications_view.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  test('should have correct routes defined', () {
    // Arrange
    final routes = AppRouter.routes;

    // Assert
    expect(routes.length, 7);
    expect(routes[0].name, AppRouter.main);
    expect(routes[0].page(), isA<MainView>());
    expect(routes[1].name, AppRouter.trade);
    expect(routes[1].page(), isA<TradeView>());
    expect(routes[2].name, AppRouter.momentary);
    expect(routes[2].page(), isA<MomentaryView>());
    expect(routes[3].name, AppRouter.surge);
    expect(routes[3].page(), isA<SurgeView>());
    expect(routes[4].name, AppRouter.volume);
    expect(routes[4].page(), isA<VolumeView>());
    expect(routes[5].name, AppRouter.settings);
    expect(routes[5].page(), isA<SettingsView>());
    expect(routes[6].name, AppRouter.notifications);
    expect(routes[6].page(), isA<NotificationsView>());
  });
}