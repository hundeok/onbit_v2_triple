import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/socket/socket_service.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';

class DataService {
  final SocketService socketService;
  final SignalBus signalBus;
  final RxList<String> markets = ['KRW-BTC', 'KRW-ETH'].obs;

  DataService({
    required this.socketService,
    required this.signalBus,
  });

  void fetchSymbols(List<String> newMarkets) {
    markets.assignAll(newMarkets);
    connectWebSocket();
  }

  void connectWebSocket() {
    socketService.updateMarkets(markets);
    socketService.connect();
  }

  void dispose() {
    markets.close();
  }
}