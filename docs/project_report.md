# 🧠 onbit_v2_triple 프로젝트 리포트

> 자동 생성 시점: 2025-05-07 17:46:36

- 목적: 실시간 크립토 분석 + 자동화 트레이딩 시스템
- 아키텍처: 4-Layer Clean Architecture (core/data/domain/presentation)
- AI 협업 구조: GPT + Claude + Groq 기반 트리플 분석

---


## 🗂️ 프로젝트 디렉토리 구조

```
.
├── analysis_options.yaml
├── android
│   ├── app
│   │   ├── build.gradle.kts
│   │   └── src
│   ├── build.gradle.kts
│   ├── gradle
│   │   └── wrapper
│   ├── gradle.properties
│   ├── gradlew
│   ├── gradlew.bat
│   ├── local.properties
│   ├── onbit_v2_triple_android.iml
│   └── settings.gradle.kts
├── assets
│   └── icon.png
├── codecov
├── dev
├── docs
│   ├── CHANGELOG.md
│   ├── module_summary.md
│   ├── project_snapshot.md
│   ├── workflow_summary.md
│   └── workflows.md
├── gpt_context
│   ├── context.json
│   └── context.md
├── ios
│   ├── Flutter
│   │   ├── AppFrameworkInfo.plist
│   │   ├── Debug.xcconfig
│   │   ├── flutter_export_environment.sh
│   │   ├── Generated.xcconfig
│   │   └── Release.xcconfig
│   ├── Podfile
│   ├── Runner
│   │   ├── AppDelegate.swift
│   │   ├── Assets.xcassets
│   │   ├── Base.lproj
│   │   ├── GeneratedPluginRegistrant.h
│   │   ├── GeneratedPluginRegistrant.m
│   │   ├── Info.plist
│   │   └── Runner-Bridging-Header.h
│   ├── Runner.xcodeproj
│   │   ├── project.pbxproj
│   │   ├── project.xcworkspace
│   │   └── xcshareddata
│   ├── Runner.xcworkspace
│   │   ├── contents.xcworkspacedata
│   │   ├── xcshareddata
│   │   └── xcuserdata
│   └── RunnerTests
│       └── RunnerTests.swift
├── l10n
│   ├── en.arb
│   └── ko.arb
├── lib
│   ├── app.dart
│   ├── core
│   │   ├── config
│   │   ├── di
│   │   ├── error
│   │   ├── lifecycle
│   │   ├── logger
│   │   ├── memory
│   │   ├── navigation
│   │   ├── network
│   │   ├── pipeline
│   │   ├── sample.dart
│   │   ├── scaling
│   │   ├── services
│   │   ├── storage
│   │   ├── streaming
│   │   ├── theme
│   │   └── workers
│   ├── data
│   │   ├── datasources
│   │   ├── models
│   │   ├── processors
│   │   └── repositories
│   ├── domain
│   │   ├── entities
│   │   ├── events
│   │   ├── repositories
│   │   └── usecases
│   ├── main.dart
│   ├── presentation
│   │   ├── app.dart
│   │   ├── common
│   │   ├── controllers
│   │   ├── pages
│   │   └── widgets
│   └── utils
├── linux
│   ├── CMakeLists.txt
│   ├── flutter
│   │   ├── CMakeLists.txt
│   │   ├── ephemeral
│   │   ├── generated_plugin_registrant.cc
│   │   ├── generated_plugin_registrant.h
│   │   └── generated_plugins.cmake
│   └── runner
│       ├── CMakeLists.txt
│       ├── main.cc
│       ├── my_application.cc
│       └── my_application.h
├── macos
│   ├── Flutter
│   │   ├── ephemeral
│   │   ├── Flutter-Debug.xcconfig
│   │   ├── Flutter-Release.xcconfig
│   │   └── GeneratedPluginRegistrant.swift
│   ├── Podfile
│   ├── Runner
│   │   ├── AppDelegate.swift
│   │   ├── Assets.xcassets
│   │   ├── Base.lproj
│   │   ├── Configs
│   │   ├── DebugProfile.entitlements
│   │   ├── Info.plist
│   │   ├── MainFlutterWindow.swift
│   │   └── Release.entitlements
│   ├── Runner.xcodeproj
│   │   ├── project.pbxproj
│   │   ├── project.xcworkspace
│   │   └── xcshareddata
│   ├── Runner.xcworkspace
│   │   ├── contents.xcworkspacedata
│   │   └── xcshareddata
│   └── RunnerTests
│       └── RunnerTests.swift
├── onbit_v2_triple.iml
├── pubspec.lock
├── pubspec.yaml
├── README.md
├── test
│   ├── core
│   │   ├── error
│   │   ├── logger
│   │   └── sample_test.dart
│   ├── data
│   │   ├── datasources
│   │   └── repositories
│   ├── domain
│   │   ├── entities
│   │   └── usecases
│   ├── integration
│   │   └── app_flow_test.dart
│   ├── presentation
│   │   ├── controllers
│   │   └── widgets
│   └── widget_test.dart
├── tool
│   └── watch_build.sh
├── web
│   ├── favicon.png
│   ├── icons
│   │   ├── Icon-192.png
│   │   ├── Icon-512.png
│   │   ├── Icon-maskable-192.png
│   │   └── Icon-maskable-512.png
│   ├── index.html
│   └── manifest.json
└── windows
    ├── CMakeLists.txt
    ├── flutter
    │   ├── CMakeLists.txt
    │   ├── ephemeral
    │   ├── generated_plugin_registrant.cc
    │   ├── generated_plugin_registrant.h
    │   └── generated_plugins.cmake
    └── runner
        ├── CMakeLists.txt
        ├── flutter_window.cpp
        ├── flutter_window.h
        ├── main.cpp
        ├── resource.h
        ├── resources
        ├── runner.exe.manifest
        ├── Runner.rc
        ├── utils.cpp
        ├── utils.h
        ├── win32_window.cpp
        └── win32_window.h

94 directories, 91 files

```


## 📅 최근 변경 사항 (CHANGELOG)

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


## 🔁 GitHub Workflows 요약

### 🛠️ codecov.yml
- **Name**: Trigger Codecov
- **Jobs**: coverage
- **Steps**:
  - Checkout repository
  - Set up Flutter
  - Install dependencies
  - Run tests with coverage
  - Upload coverage to Codecov

### 🛠️ flutter_changelog.yml
- **Name**: Flutter Changelog
- **Jobs**: generate-changelog
- **Steps**:
  - Checkout code
  - Set Git config
  - Generate CHANGELOG.md
  - Commit changelog

### 🛠️ flutter_ci.yml
- **Name**: Flutter CI
- **Jobs**: build
- **Steps**:
  - Checkout repository
  - Set up Flutter
  - Install dependencies
  - Analyze code
  - Run tests with coverage
  - Upload coverage to Codecov

### 🛠️ flutter_module_summary.yml
- **Name**: Flutter Module Summary
- **Jobs**: generate-summary
- **Steps**:
  - Checkout code
  - Generate module summary
  - Git commit

### 🛠️ flutter_readme_badge3.yml
- **Name**: Flutter README Badge
- **Jobs**: update-readme
- **Steps**:
  - Checkout Repository
  - Append Badge to README
  - Commit and Push Changes

### 🛠️ flutter_snapshot.yml
- **Name**: Flutter Project Snapshot
- **Jobs**: generate-snapshot
- **Steps**:
  - Checkout code
  - Install tree
  - Generate project snapshot
  - Commit & Push Snapshot

### 🛠️ flutter_summarize.yml
- **Name**: Flutter Summarize lib/ Structure
- **Jobs**: summarize
- **Steps**:
  - Checkout code
  - Install tree
  - Generate lib/ module summary
  - Commit module summary

### 🛠️ gpt_context.yml
- **Name**: GPT Context Snapshot
- **Jobs**: generate-context
- **Steps**:
  - Checkout code
  - Ensure jq is available
  - Create GPT context files
  - Commit & Push GPT context



## 🎯 주요 유즈케이스 / 우선순위 작업

- [x] 소켓 기반 실시간 트레이드 데이터 수신
- [x] Skeleton UI + trade_card 위젯 구성
- [x] get_filtered_trades 유즈케이스 설계
- [ ] Phase 2: Alert Controller 설계 + 백프레셔 처리


## 🧠 GPT Context Snapshot

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
