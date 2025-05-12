import 'package:dartz/dartz.dart';
import 'package:onbit_v2_triple/core/error/failure.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';

/// 거래소 데이터를 처리하는 리포지토리 인터페이스.
/// - 실시간 WebSocket과 REST API를 통해 거래 데이터를 관리.
/// - 지원 거래소: Upbit, Binance 등 확장 가능.
/// @see [TradeRepositoryImpl] for implementation details.
abstract class TradeRepository {
  /// 실시간 거래 데이터를 WebSocket 스트림으로 구독.
  /// - [markets]: 구독할 마켓 심볼 리스트 (예: ['KRW-BTC', 'KRW-ETH']).
  /// @returns [Stream<Either<Failure, Trade>>] 성공 시 거래 데이터, 실패 시 에러.
  /// @throws [InvalidInputFailure] 빈 마켓 리스트 제공 시.
  Stream<Either<Failure, Trade>> subscribeLiveTrades(List<String> markets);

  /// 사용 가능한 마켓 심볼 목록을 조회.
  /// @returns [Future<Either<Failure, List<String>>>] 성공 시 마켓 심볼 리스트, 실패 시 에러.
  /// @throws [ServerFailure] API 서버 에러 발생 시.
  Future<Either<Failure, List<String>>> getAvailableMarkets();

  /// 최근 거래 내역을 조회.
  /// - [symbol]: 조회할 마켓 심볼 (예: 'KRW-BTC').
  /// - [limit]: 반환할 최대 거래 수 (기본값: 50).
  /// @returns [Future<Either<Failure, List<Trade>>>] 성공 시 거래 리스트, 실패 시 에러.
  /// @throws [InvalidInputFailure] 유효하지 않은 심볼 제공 시.
  Future<Either<Failure, List<Trade>>> getRecentTrades(
    String symbol, {
    int limit = 50,
  });

  /// 최소 거래 금액 기준으로 필터링된 거래 내역을 조회.
  /// - [symbol]: 조회할 마켓 심볼.
  /// - [minAmount]: 최소 거래 금액 필터.
  /// - [limit]: 반환할 최대 거래 수 (기본값: 50).
  /// @returns [Future<Either<Failure, List<Trade>>>] 성공 시 필터링된 거래 리스트, 실패 시 에러.
  /// @throws [NoDataFailure] 거래 데이터 없음.
  Future<Either<Failure, List<Trade>>> getTradesByVolume(
    String symbol,
    double minAmount, {
    int limit = 50,
  });

  /// 특정 시간 범위 내 거래 내역을 조회.
  /// - [symbol]: 조회할 마켓 심볼.
  /// - [startTime]: 조회 시작 시간 (Unix timestamp).
  /// - [endTime]: 조회 종료 시간 (Unix timestamp).
  /// - [limit]: 반환할 최대 거래 수 (기본값: 50).
  /// @returns [Future<Either<Failure, List<Trade>>>] 성공 시 거래 리스트, 실패 시 에러.
  /// @throws [InvalidInputFailure] 유효하지 않은 시간 범위 제공 시.
  Future<Either<Failure, List<Trade>>> getTradesByTimeRange(
    String symbol,
    int startTime,
    int endTime, {
    int limit = 50,
  });

  /// 리소스를 정리하고 구독을 종료.
  /// @note 모든 WebSocket 및 REST 연결 해제.
  void dispose();
}