import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/di/tags.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';
import 'package:onbit_v2_triple/presentation/pages/splash/splash_view.dart';
import 'package:onbit_v2_triple/presentation/pages/trade/trade_view.dart';
import 'package:onbit_v2_triple/presentation/pages/volume/volume_view.dart';
import 'package:onbit_v2_triple/presentation/pages/surge/surge_view.dart';
import 'package:onbit_v2_triple/presentation/pages/momentary/momentary_view.dart';

/// 이벤트 클래스 - 라우트 이동
class RouteNavigatedEvent extends SignalEvent {
  final String route;
  
  RouteNavigatedEvent(this.route);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'route_navigated',
    'route': route,
    'timestamp': DateTime.now().toIso8601String(),
  };
}

/// 이벤트 클래스 - 라우트 오류
class RouteErrorEvent extends SignalEvent {
  final String message;
  final Object? error;
  
  RouteErrorEvent(this.message, {this.error});
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'route_error',
    'message': message,
    'error': error?.toString(),
    'timestamp': DateTime.now().toIso8601String(),
  };
}

/// 애플리케이션 네비게이션 라우터.
/// - [Get] 기반으로 라우트 정의 및 관리.
/// - [SplashView], [TradeView], [VolumeView], [SurgeView], [MomentaryView] 지원.
/// @see [GetPage] for route configuration.
class AppRouter {
  /// 초기 라우트 경로.
  static const String initialRoute = '/splash';
  
  /// 라우트 목록.
  static final List<GetPage> routes = [
    GetPage(
      name: '/splash',
      page: () => const SplashView(),
    ),
    GetPage(
      name: '/trade',
      page: () => const TradeView(),
    ),
    GetPage(
      name: '/volume',
      page: () => const VolumeView(),
    ),
    GetPage(
      name: '/surge',
      page: () => const SurgeView(),
    ),
    GetPage(
      name: '/momentary',
      page: () => const MomentaryView(),
    ),
  ];
  
  /// 라우트 유효성 검사 및 이동.
  /// - [route]: 이동할 라우트 경로.
  /// - [arguments]: 라우트에 전달할 인자.
  /// - [metricLogger]: 메트릭 로거 (선택).
  /// - [signalBus]: 이벤트 버스 (선택).
  /// @throws [InvalidInputException] 유효하지 않은 라우트 경로.
  static void navigateTo(
    String route, {
    dynamic arguments,
    MetricLogger? metricLogger,
    SignalBus? signalBus,
  }) {
    if (!_isValidRoute(route)) {
      final error = InvalidInputException(message: 'Invalid route: $route');
      metricLogger?.incrementCounter('navigation_errors', labels: {'route': route});
      signalBus?.fire(RouteErrorEvent(error.message, error: error));
      throw error;
    }
    
    Get.toNamed(route, arguments: arguments);
    metricLogger?.incrementCounter('navigations', labels: {'route': route});
    signalBus?.fire(RouteNavigatedEvent(route));
  }
  
  /// 라우트 유효성 검사.
  /// - [route]: 검사할 라우트 경로.
  /// @returns 유효하면 true.
  static bool _isValidRoute(String route) {
    return routes.any((page) => page.name == route);
  }
  
  /// 초기 라우트 유효성 검사.
  /// - [metricLogger]: 메트릭 로거 (선택).
  /// - [signalBus]: 이벤트 버스 (선택).
  /// @throws [InvalidInputException] 초기 라우트가 유효하지 않을 경우.
  static void validateInitialRoute({MetricLogger? metricLogger, SignalBus? signalBus}) {
    if (!_isValidRoute(initialRoute)) {
      final error = InvalidInputException(message: 'Invalid initial route: $initialRoute');
      metricLogger?.incrementCounter('navigation_errors', labels: {'route': initialRoute});
      signalBus?.fire(RouteErrorEvent(error.message, error: error));
      throw error;
    }
  }
}