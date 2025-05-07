# 🧠 GPT Context Snapshot
Generated at: #오후

## 📄 README

# 🧠 onbit_v2_triple

[![Flutter CI](https://github.com/hundeok/onbit_v2_triple/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/hundeok/onbit_v2_triple/actions/workflows/flutter_ci.yml)
[![Code Coverage](https://codecov.io/gh/hundeok/onbit_v2_triple/branch/main/graph/badge.svg?token=5182d729-a03f-4417-8aea-7687b9307e84)](https://codecov.io/gh/hundeok/onbit_v2_triple)
![Branch](https://img.shields.io/badge/branch-main-blue)

---

AI 기반 트리플 협업 코인 프로젝트.  
GPT + Claude + Groq 구조로 구성된 초고속 자동화 시스템.

## 🧩 구성

- `core/`: 공통 유틸 및 베이스 컴포넌트
- `data/`: API 연동 및 모델 정의
- `domain/`: 비즈니스 로직 및 리포지토리
- `presentation/`: UI, 상태관리, 라우팅 구성

## ✅ 기능 목표

- 실시간 코인 데이터 분석 및 시각화
- 3단계 AI 협업 구조로 구성된 전략 로직
- 자동화 트레이딩 & 실시간 이벤트 처리

## 🚀 실행 방법

```bash
flutter pub get
flutter run


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
Test trigger at #오후
