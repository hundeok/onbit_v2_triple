# 🧠 onbit_v2_triple 프로젝트 리포트

> 자동 생성 시점: 2025-05-07 17:49:09

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
│   ├── project_report.md
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

94 directories, 92 files

```

## 📅 최근 변경 사항 (CHANGELOG)

### 🔄 Recent Commits

- ci: add auto project report workflow (d94dd70)
- docs: add full auto-generated project report (9020889)
- chore: add workflow summary & extraction tools (d60a46c)
- chore: ignore dev folder (1a359f8)
- chore: 최종 프로젝트 구조 정리 및 ignore dev 폴더 (27906a3)
- chore: ignore unused dev folder (12fd874)
- test: trigger workflow (55bdd2e)
- test: manual context generation (0b174ce)
- temp: save local changes before pull (5e29aed)
- chore: use latest stable Flutter version (5c6b6d2)

## 🔁 GitHub Workflows 요약

### 🛠️ auto_project_report.yml
- **Name**: Auto Project Report
- **Jobs**: generate-project-report
- **Steps**:
  - Checkout code
  - Set up Python
  - Install dependencies
  - Generate Project Report
  - Commit and Push Project Report

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

