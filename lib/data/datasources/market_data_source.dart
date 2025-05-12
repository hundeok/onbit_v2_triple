import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/data/models/market_model.dart';
import 'package:onbit_v2_triple/data/models/trade_model.dart';

/// 시장 데이터 소스 인터페이스.
/// - REST API를 통해 마켓 심볼, 가격, 체결, 캔들, 요약 데이터 제공.
/// - [ApiService]와 연동, [TradeRepositoryImpl]에서 사용.
/// @throws [ServerException] 서버 에러.
/// @throws [NetworkException] 네트워크 에러.
/// @throws [RateLimitException] API 제한 초과.
/// @throws [InvalidInputException] 잘못된 입력.
abstract class MarketDataSource {
  /// 사용 가능한 모든 마켓 심볼 목록 조회.
  /// @returns [List<String>] 마켓 심볼 리스트 (예: ['KRW-BTC', 'KRW-ETH']).
  Future<List<String>> getAllSymbols();

  /// 심볼 유효성 검증.
  /// - [symbol]: 검증할 마켓 심볼 (예: 'KRW-BTC').
  /// @returns [bool] 심볼 유효 여부.
  Future<bool> isValidSymbol(String symbol);

  /// 특정 마켓의 현재 가격 정보 조회.
  /// - [symbol]: 마켓 심볼.
  /// @returns [MarketModel] 시장 가격 데이터.
  Future<MarketModel> getMarketPrice(String symbol);

  /// 여러 마켓의 가격 정보 동시 조회.
  /// - [symbols]: 마켓 심볼 리스트.
  /// @returns [Map<String, MarketModel>] 심볼별 시장 가격 데이터.
  Future<Map<String, MarketModel>> getMultipleMarketPrices(List<String> symbols);

  /// 특정 마켓의 최근 체결 내역 조회.
  /// - [symbol]: 마켓 심볼.
  /// - [limit]: 최대 체결 건수 (기본값: 50).
  /// @returns [List<TradeModel>] 체결 데이터 리스트.
  Future<List<TradeModel>> getRecentTrades(String symbol, {int limit = 50});

  /// 특정 마켓의 캔들스틱(OHLCV) 데이터 조회.
  /// - [symbol]: 마켓 심볼.
  /// - [interval]: 캔들 간격 (예: '1m', '1h', '1d').
  /// - [limit]: 최대 캔들 개수 (기본값: 100).
  /// @returns [List<Map<String, dynamic>>] 캔들 데이터 리스트.
  /// @throws [InvalidInputException] 유효하지 않은 interval 제공 시.
  Future<List<Map<String, dynamic>>> getCandles(String symbol, String interval, {int limit = 100});

  /// 특정 용량(거래 금액) 이상의 체결 내역 조회.
  /// - [symbol]: 마켓 심볼.
  /// - [minAmount]: 최소 거래 금액.
  /// - [limit]: 최대 체결 건수 (기본값: 50).
  /// @returns [List<TradeModel>] 필터링된 체결 데이터 리스트.
  Future<List<TradeModel>> getTradesByVolume(String symbol, double minAmount, {int limit = 50});

  /// 특정 기간 동안의 체결 내역 조회.
  /// - [symbol]: 마켓 심볼.
  /// - [startTime]: 시작 시간 (Unix timestamp, 밀리초).
  /// - [endTime]: 종료 시간 (Unix timestamp, 밀리초).
  /// - [limit]: 최대 체결 건수 (기본값: 50).
  /// @returns [List<TradeModel>] 필터링된 체결 데이터 리스트.
  /// @throws [InvalidInputException] 유효하지 않은 시간 범위 제공 시.
  Future<List<TradeModel>> getTradesByTimeRange(String symbol, int startTime, int endTime, {int limit = 50});

  /// 마켓 시세 요약 정보 조회 (24시간 변동률, 거래량 등).
  /// - [symbol]: 마켓 심볼.
  /// @returns [Map<String, dynamic>] 요약 데이터 (예: {'change_rate': 0.05, 'volume': 1000}).
  Future<Map<String, dynamic>> getMarketSummary(String symbol);

  /// 리소스 정리.
  /// - 구현체에서 HTTP 클라이언트, 캐시 등 정리.
  void dispose();
}