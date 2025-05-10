# 🧠 GPT Context Snapshot
Generated at: 2025-05-10 18:39:40 KST

## 📄 README

# 🧠 onbit_v2_triple

[![Flutter CI](https://github.com/hundeok/onbit_v2_triple/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/hundeok/onbit_v2_triple/actions/workflows/flutter_ci.yml)  
[![Code Coverage](https://codecov.io/gh/hundeok/onbit_v2_triple/branch/main/graph/badge.svg?token=5182d729-a03f-4417-8aea-7687b9307e84)](https://codecov.io/gh/hundeok/onbit_v2_triple)  
![Branch](https://img.shields.io/badge/branch-main-blue)

---

## 🧠 프로젝트 개요

**AI × 실시간 하이브리드 트레이딩 시스템**  
GPT + Claude + Groq 기반의 트리플 협업 자동화 구조.  
WebSocket + REST API 하이브리드 통신 체제를 도입하여  
**“실시간성 × 안정성”**을 동시에 확보한 고성능 코인 분석 앱입니다.

---

## 🧩 아키텍처 구조

core/
├── socket/ ← WebSocket 커넥션 전담
├── api/ ← Dio 기반 REST 처리
├── bridge/ ← 소켓/REST 데이터 허브 (옵션)
data/
├── sources/ ← socket_, rest_ 분리
├── repositories/ ← 실시간 + 백업 소스 통합
domain/
├── entities/, usecases/, repositories/
presentation/
├── controllers/, pages/, widgets/


> ✅ `4 Layer Clean Architecture`  
> ✅ `GetX 기반 단방향 흐름`  
> ✅ `WebSocket 주도 + REST 백업 하이브리드 체계`

---

## ✅ 주요 기능

- 실시간 체결 데이터 감지 및 누적 시각화
- 소켓 기반 고속 반응 시스템 + REST 초기화 로직
- 트리플 AI 협업 (GPT/Claude/Groq) 로직 통합
- 자동화 시그널 감지 + 조건 기반 트레이딩 구조화

---

## 🚀 실행 방법

```bash
flutter pub get
bash tool/watch_build.sh     # json_serializable 자동 생성
flutter run
🧪 테스트

flutter test
flutter test --coverage
통합 테스트: test/integration/app_flow_test.dart
커버리지 목표: 80%+
사용 툴: mockito, patrol, mock_server
🧠 설계 철학

항목	기준
파일명	snake_case.dart
클래스명	PascalCase
import 규칙	같은 레이어: 상대경로 / 크로스 레이어: package:onbit_v2_triple/
DI 구조	Get.lazyPut(() => X(), tag: 'data.xxx')
에러 처리	Either<Failure, T> + .fold() 처리
상태 공유	GetX Controller 최소화 + .putAsync() 재시도 포함
기술부채 추적	// TODO: [TECH-DEBT] + GitHub Issues 연결
🌍 다국어 지원

.arb 파일 (en.arb, ko.arb)
flutter gen-l10n 자동화
l10n.yaml: nullable-getter: false
🔄 통신 체제 (하이브리드 전략)

흐름	기술	주기
초기 로딩	REST	앱 진입 시 1회
실시간 체결 감시	WebSocket	상시 연결 유지
리프레시 백업	REST	30초~2분 간격 또는 실패 시
소켓 실패 대비	REST fallback	즉시
WebSocket = 실시간, 빠름
REST = 백업, 정합성 보완
🚧 CI/CD 자동화

GitHub Actions
flutter analyze
flutter test
flutter build --release --obfuscate
flutter build --analyze-size
문서: CHANGELOG.md, CONTRIBUTING.md
브랜치 네이밍:
feature/socket-stream
fix/trade-bug
📈 성능 모니터링

PerformanceOverlay + profile 빌드
StreamQueue/compute() 최적화
Rx throttle/debounce 연산 사용
🔐 프로덕션 대응

SSL 핀닝 (Dio)
Secure Storage → timeout + catch
Crashlytics + 로그 gzip 압축 로테이션
UX 안정화: Skeleton Loader, Fallback UI, 상태 표시 바
📦 실행 우선순위 (Phase 1)

core/socket/socket_service.dart
data/sources/socket_trade_source.dart
presentation/widgets/trade_card.dart
domain/usecases/subscribe_live_trades.dart
test/integration/app_flow_test.dart
📎 문서 & 참고

docs/extension_points.md → 확장 기준
analysis_options.yaml → lint 규칙
tool/watch_build.sh → 빌드 자동화 스크립트
build.yaml → explicit_to_json: true
✊ 프로젝트 선언

이 프로젝트는 단순한 앱이 아닙니다.
실시간 + 자동화 + AI 기반 트레이딩 프레임워크의 시작점입니다.
모든 협업자 및 AI Agent는 위 구조를 기반으로
클래스, 유즈케이스, 컨트롤러를 정확히 구성해야 합니다.

## 📦 프로젝트 디렉토리 구조

lib/
├── app.dart                           # 앱 진입 설정, MaterialApp 라우팅 등
├── core
│   ├── api
│   │   └── api_service.dart           # REST API 요청 (Dio 기반)
│   ├── bridge
│   │   └── data_bus.dart              # REST ↔ WebSocket 간 데이터 허브/변환기
│   ├── config
│   │   ├── app_config.dart            # 앱 환경 설정 클래스
│   │   └── env_config.dart            # prod/dev 환경 구분 및 env 변수 정의
│   ├── di
│   │   ├── bindings
│   │   │   ├── controller_binding.dart     # GetX Controller 등록
│   │   │   ├── data_source_binding.dart    # DataSource DI 등록
│   │   │   ├── processor_binding.dart      # 데이터 처리 계층 DI
│   │   │   ├── repository_binding.dart     # Repository DI
│   │   │   ├── service_binding.dart        # Core 서비스 DI (e.g. PlatformService)
│   │   │   ├── usecase_binding.dart        # UseCase DI 등록
│   │   │   └── view_bindings.dart          # View/Page 바인딩 관리
│   │   └── injection_container.dart   # DI 초기화 컨테이너
│   ├── error
│   │   ├── exception.dart             # 예외 정의
│   │   └── failure.dart               # 실패 응답 모델 (Either 실패 케이스)
│   ├── lifecycle
│   │   └── app_lifecycle_manager.dart # 앱 포그라운드/백그라운드 감지
│   ├── logger
│   │   └── app_logger.dart            # 공통 로거 클래스 (dev/prod 대응 포함)
│   ├── memory
│   │   └── object_pool.dart           # 객체 재사용 풀 (성능 최적화용)
│   ├── navigation
│   │   └── app_router.dart            # 라우팅 관리 (GetX Routes)
│   ├── network                        # (비워둠) 추후 다중 네트워크 계층 도입 시 사용
│   ├── pipeline                       # (비워둠) 고속 필터링/데이터 리듬 제어 등 스트림 파이프라인 구성용
│   ├── scaling
│   │   └── rate_limiter.dart          # 요청 속도 제한 유틸리티
│   ├── services
│   │                                   # (비어 있음) 플랫폼 서비스 통합용 (예: FCM, 공유 등)
│   ├── socket
│   │   ├── socket_service.dart        # WebSocket 커넥션, ping/pong, reconnect
│   │   └── trade_pipeline.dart        # 실시간 체결 흐름 파이프라인 처리
│   ├── storage
│   │   └── local_storage.dart         # SharedPreferences 기반 저장소
│   ├── streaming
│   │   └── backpressure_controller.dart # 소켓 스트림 과부하 조절 유닛
│   ├── theme
│   │   ├── app_theme_manager.dart     # 테마 전환 로직
│   │   └── app_theme.dart             # 테마 정의값 (light/dark)
│   └── workers
│       └── isolate_worker.dart        # Isolate 기반 비동기 처리 유닛

├── data
│   ├── datasources
│   │   └── real_market_data_source.dart # 실제 외부 마켓 데이터 처리 소스
│   ├── models
│   │   ├── market_model.dart          # 마켓 정보 모델
│   │   ├── socket_trade_message_model.dart # WebSocket 체결 메시지 모델
│   │   └── trade_model.dart           # 일반 트레이드 데이터 모델
│   ├── processors
│   │   ├── trade_aggregator.dart      # 체결 데이터 집계 처리
│   │   └── trade_processor.dart       # 체결 데이터 분석/가공 처리
│   ├── repositories
│   │   └── trade_repository_impl.dart # 실제 데이터 조합 구현체 (REST + 소켓 통합)
│   └── sources
│       ├── rest
│       │   ├── market_data_source.dart   # REST 기반 마켓 데이터 fetch
│       │   └── rest_trade_source.dart    # REST 기반 체결 데이터 fetch
│       └── socket
│           └── socket_trade_source.dart # WebSocket 기반 실시간 체결 감시

├── domain
│   ├── entities
│   │   ├── trade.dart                 # 트레이드 도메인 모델
│   │   └── trade.g.dart               # json_serializable 자동 생성 파일
│   ├── events
│   │   └── trade_event.dart           # 체결 이벤트 정의
│   ├── repositories
│   │   └── trade_repository.dart      # Repository 추상 인터페이스
│   └── usecases
│       ├── get_filtered_trades.dart   # 조건 필터링 체결 데이터
│       ├── get_momentary_trades.dart  # 순간 체결 감지
│       ├── get_surge_trades.dart      # 급등락 감지
│       ├── get_volume_data.dart       # 거래량 기반 감지
│       └── subscribe_live_trades.dart # WebSocket 기반 실시간 구독 유즈케이스

├── generated
│   ├── intl
│   │   ├── messages_all.dart          # 다국어 메시지 all
│   │   └── messages_en.dart           # 영어 번역 파일
│   └── l10n.dart                      # 자동 생성된 intl 엔트리 포인트

├── main.dart                          # 앱 시작점

├── presentation
│   ├── app.dart                       # 앱 외부 껍데기 / 라우터 초기화
│   ├── common
│   │   ├── empty_state_widget.dart    # 비어있을 때 공통 UI
│   │   ├── error_widget.dart          # 에러 표시용 위젯
│   │   └── loading_widget.dart        # 로딩 인디케이터
│   ├── controllers
│   │   ├── locale_controller.dart     # 다국어 설정
│   │   ├── main_controller.dart       # 메인 홈 제어
│   │   ├── momentary_controller.dart  # 순간 감지 전용 컨트롤러
│   │   ├── surge_controller.dart      # 급등락 제어
│   │   ├── trade_controller.dart      # 체결 데이터 제어
│   │   └── volume_controller.dart     # 거래량 제어
│   ├── pages
│   │   ├── main/main_view.dart        # 메인 뷰
│   │   ├── momentary/momentary_view.dart # 순간 감지 뷰
│   │   ├── notifications/notifications_view.dart # 알림 페이지
│   │   ├── settings/settings_view.dart  # 설정 페이지
│   │   ├── splash/splash_view.dart      # 스플래시 화면
│   │   ├── surge/surge_view.dart        # 급등락 뷰
│   │   ├── trade/trade_view.dart        # 체결 데이터 뷰
│   │   └── volume/volume_view.dart      # 거래량 뷰
│   └── widgets
│       ├── common/connection_status_bar.dart # 네트워크 상태 표시 바
│       ├── common_app_bar.dart         # 공통 앱 바 위젯
│       ├── drawer/app_drawer.dart      # 좌측 사이드메뉴
│       ├── index.dart                  # export 모듈화
│       └── trade_card_widget.dart      # 체결 카드 UI 컴포넌트

└── utils
    └── utils                          # 공통 유틸 함수 모음




## 📝 Changelog

# 📝 Changelog
Generated at: #오후

## 🔄 Recent Commits

- docs: update README with badges (657f0e0)
- chore: add flutter summarize lib structure workflow (3182f22)
- chore: add flutter project snapshot workflow (5ac641c)
- fix: finalized flutter_readme_badge3 workflow (02c6e88)
- fix: improve flutter_module_summary workflow (3c9a230)
- fix: improve flutter_changelog.yml (0692c64)
- Fix flutter_ci.yml workflow format (b83cf63)
- Add working AppLogger and tests for coverage (aa67331)
- Add logger test to trigger real coverage (7558dfc)
- Fix: set Flutter SDK to 3.22.1 for Dart 3.4 compatibility (5220c0d)

## 📦 Module Summary

## 🧱 Module Summary - lib/ 구조

lib/
├── app.dart
├── core
│   ├── config
│   │   ├── app_config.dart
│   │   └── env_config.dart
│   ├── di
│   │   ├── bindings
│   │   │   ├── controller_binding.dart
│   │   │   ├── data_source_binding.dart
│   │   │   ├── processor_binding.dart
│   │   │   ├── repository_binding.dart
│   │   │   ├── service_binding.dart
│   │   │   ├── usecase_binding.dart
│   │   │   └── view_bindings.dart
│   │   └── injection_container.dart
│   ├── error
│   │   ├── exception.dart
│   │   └── failure.dart
│   ├── lifecycle
│   │   └── app_lifecycle_manager.dart
│   ├── logger
│   │   └── app_logger.dart
│   ├── memory
│   │   └── object_pool.dart
│   ├── navigation
│   │   └── app_router.dart
│   ├── network
│   │   ├── api_client.dart
│   │   └── connectivity_manager.dart
│   ├── pipeline
│   │   └── trade_pipeline.dart
│   ├── sample.dart
│   ├── scaling
│   │   └── rate_limiter.dart
│   ├── services
│   │   └── platform_service.dart
│   ├── storage
│   │   └── local_storage.dart
│   ├── streaming
│   │   └── backpressure_controller.dart
│   ├── theme
│   │   ├── app_theme_manager.dart
│   │   └── app_theme.dart
│   └── workers
│       └── isolate_worker.dart
├── data
│   ├── datasources
│   │   ├── market_data_source.dart
│   │   ├── mock_market_data_source.dart
│   │   ├── real_market_data_source.dart
│   │   ├── socket_trade_source.dart
│   │   └── trade_data_source.dart
│   ├── models
│   │   ├── market_model.dart
│   │   └── trade_model.dart
│   ├── processors
│   │   └── trade_processor.dart
│   └── repositories
│       └── trade_repository_impl.dart
├── domain
│   ├── entities
│   │   └── trade.dart
│   ├── events
│   │   └── trade_event.dart
│   ├── repositories
│   │   └── trade_repository.dart
│   └── usecases
│       ├── get_filtered_trades.dart
│       ├── get_momentary_trades.dart
│       ├── get_surge_trades.dart
│       └── get_volume_data.dart
├── main.dart
├── presentation
│   ├── app.dart
│   ├── common
│   │   ├── empty_state_widget.dart
│   │   ├── error_widget.dart
│   │   └── loading_widget.dart
│   ├── controllers
│   │   ├── main_controller.dart
│   │   ├── momentary_controller.dart
│   │   ├── surge_controller.dart
│   │   ├── trade_controller.dart
│   │   └── volume_controller.dart
│   ├── pages
│   │   ├── main
│   │   │   └── main_view.dart
│   │   ├── momentary
│   │   │   └── momentary_view.dart
│   │   ├── notifications
│   │   │   └── notifications_view.dart
│   │   ├── settings
│   │   │   └── settings_view.dart
│   │   ├── splash
│   │   │   └── splash_view.dart
│   │   ├── surge
│   │   │   └── surge_view.dart
│   │   ├── trade
│   │   │   └── trade_view.dart
│   │   └── volume
│   │       └── volume_view.dart
│   └── widgets
│       ├── common
│       │   └── connection_status_bar.dart
│       ├── common_app_bar.dart
│       ├── drawer
│       │   └── app_drawer.dart
│       ├── index.dart
│       └── trade_card_widget.dart
└── utils

44 directories, 67 files
